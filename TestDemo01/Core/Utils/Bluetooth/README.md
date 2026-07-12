# 蓝牙模块设计文档

## 一、模块概览

本模块封装了基于 CoreBluetooth 的完整 BLE（低功耗蓝牙）通信流程，从设备扫描、连接、服务发现到数据传输，提供了一套开箱即用的通信框架。

### 文件结构

```
Core/Utils/Bluetooth/
├── BluetoothManager.swift           ← 核心管理器（单例），统筹扫描/连接/传输
├── BluetoothProfile.swift           ← 协议画像体系（角色、状态机、指标）
├── BluetoothTransferProtocol.swift  ← 应用层协议（帧结构、编解码、CRC32）
└── README.md                        ← 本文档

Features/UIKitDemo/Bluetooth/
├── BluetoothDemoController.swift     ← Demo UI 控制器（UIKit + Combine 绑定）
└── BluetoothDemoViewModel.swift      ← Demo ViewModel（蓝牙事件 → UI 数据）
```

### 架构分层

```
┌──────────────────────────────────────────────────┐
│                  UI 层 (Controller)                │
│            BluetoothDemoController                 │
│          （按钮状态绑定 / TableView / 日志）         │
├──────────────────────────────────────────────────┤
│               ViewModel 层                         │
│           BluetoothDemoViewModel                   │
│      （@Published 属性 / 业务方法 / 日志）           │
├──────────────────────────────────────────────────┤
│               核心管理层                            │
│             BluetoothManager                       │
│   （扫描 / 连接 / 重连 / 传输调度 / 状态机）         │
├───────────────┬──────────────────────────────────┤
│  协议画像层     │         应用层协议层                 │
│ BluetoothProfile│  BluetoothTransferProtocol       │
│（角色/状态/指标） │ （帧结构/编解码/CRC32）            │
└───────────────┴──────────────────────────────────┘
```

---

## 二、核心概念

### 2.1 特征角色（BluetoothCharacteristicRole）

不直接传 UUID，而是用业务角色表达"这条通道用来干什么"：

| 角色 | 用途 | 典型 UUID 示例 |
|------|------|---------------|
| `.commandWrite` | 发送简短指令（PING、开关灯） | 自定义 |
| `.dataWrite` | 发送大块数据（文件、OTA 固件） | 自定义 |
| `.notify` | 外设主动推送数据给 App | 自定义 |
| `.read` | App 主动读取外设的值 | 自定义 |

### 2.2 设备协议画像（BluetoothDeviceProfile）

一类硬件设备的蓝牙协议定义，包括扫描 UUID、服务列表、特征映射：

```
BluetoothDeviceProfile
├── scanServiceUUIDs: [CBUUID]?     ← 扫描时过滤的 service UUID
├── serviceUUIDs: [CBUUID]?         ← 连接后需要发现的服务
├── characteristics: [BluetoothCharacteristicProfile]  ← 特征定义
│   ├── role: .commandWrite
│   ├── serviceUUID: ...
│   ├── characteristicUUID: ...
│   ├── enableNotify: true/false
│   └── preferredWriteType: .withResponse / .withoutResponse
└── genericDemo (静态预设)          ← Demo 模式，全量扫描、自动猜测角色
```

### 2.3 连接状态机（BluetoothConnectionState）

```
                     ┌──────────────────────────────────────────┐
                     │                                          │
    ┌──────┐  startScan  ┌──────────┐  stopScan/timeout  ┌──────┐
    │ idle │ ──────────→ │ scanning │ ─────────────────→ │ idle │
    └──────┘              └──────────┘                    └──────┘
       │                        │
       │ connect(device)        │ connect(device)
       ▼                        ▼
    ┌───────────┐  CBDidConnect  ┌──────────────┐  discoverServices+Characteristics
    │ connecting │ ────────────→ │ discovering  │ ──────────────────────────→
    └───────────┘                └──────────────┘
                                  │
                                  ▼
                            ┌───────┐  disconnect  ┌───────────────┐
                            │ ready │ ──────────→ │ disconnecting  │
                            └───────┘              └───────────────┘
                               │ 异常断开                  │
                               │ error != nil              ▼
                               ▼                    ┌──────────────┐
                          ┌──────────────┐          │ disconnected │
                          │ reconnecting │          └──────────────┘
                          │ (指数退避)    │
                          └──────────────┘
                               │ 超过最大重连次数
                               ▼
                          ┌────────┐
                          │ failed │
                          └────────┘
```

### 2.4 运行时指标（BluetoothMetricSnapshot）

| 指标 | 含义 |
|------|------|
| `connectStartedAt` | 连接开始时间戳 |
| `readyAt` | 特征就绪时间戳 |
| `connectionCost` | 连接耗时（秒）= readyAt - connectStartedAt |
| `reconnectAttempts` | 已尝试重连次数 |
| `transmittedBytes` | 已发送字节数 |
| `receivedBytes` | 已接收字节数 |
| `lastRSSI` | 最近一次扫描到的信号强度 |
| `maximumWriteLength` | 当前外设支持的最大写入长度 |

---

## 三、应用层协议设计

### 3.1 帧结构

所有可靠传输的数据都封装在应用层帧中，帧布局如下（大端序）：

```
┌──────────┬─────────┬──────┬──────────┬────────┬─────────────┬────────────┬────────┬─────────┐
│ magic    │ version │ type │ sequence │ offset │ totalLength │ payloadLen │ crc32  │ payload │
│ (2 Byte) │ (1 Byte)│(1 B) │ (4 Byte) │(4 Byte)│  (4 Byte)   │  (2 Byte)  │(4 Byte)│ (N B)   │
│ 0xA55A   │ 0x01    │      │          │        │             │            │        │         │
└──────────┴─────────┴──────┴──────────┴────────┴─────────────┴────────────┴────────┴─────────┘
|<──────────────────────── 头部固定 22 字节 ──────────────────────────────>|<── 可变长度 ──>|
```

### 3.2 帧类型

| 类型 | 值 | 方向 | 说明 |
|------|----|------|------|
| `.data` | 1 | App → 外设 | 携带实际 payload 的数据帧 |
| `.ack` | 2 | 外设 → App | 确认收到某个序号的数据包 |
| `.complete` | 3 | 预留 | 标记整个传输结束（当前未使用） |
| `.resumeRequest` | 4 | 预留 | 请求从某个 offset 续传（当前未使用） |

### 3.3 解码校验流程

```
收到原始字节
    │
    ├─ 长度 < 22？ ──→ 丢弃（连头部都不够）
    │
    ├─ magic != 0xA55A？ ──→ 丢弃（不是合法帧）
    │
    ├─ version != 1？ ──→ 丢弃（版本不兼容）
    │
    ├─ type 无法识别？ ──→ 丢弃
    │
    ├─ payloadEnd > data.count？ ──→ 丢弃（长度不匹配）
    │
    ├─ CRC32 校验失败？ ──→ 丢弃（数据损坏）
    │
    └─ 全部通过 ──→ 返回 BluetoothProtocolFrame
```

### 3.4 CRC32 算法

- 多项式：`0xEDB88320`（IEEE 802.3 标准）
- 初始值：`0xFFFFFFFF`
- 最终异或：`0xFFFFFFFF`
- 逐字节计算，无需查表，适合嵌入式场景

---

## 四、BluetoothManager 核心能力

### 4.1 扫描

| 方法 | 说明 |
|------|------|
| `startScan(serviceUUIDs:timeout:)` | 开始扫描，可指定 service UUID 过滤和超时 |
| `stopScan()` | 停止扫描，状态切回 `.idle` |
| `retrieveKnownPeripherals(identifiers:)` | 从系统缓存检索之前连接过的设备 |
| `retrieveConnectedPeripherals(serviceUUIDs:)` | 检索系统已连接的外设 |

- 扫描结果自动按 RSSI 降序排列
- 同一设备发现多次会更新 RSSI，不会重复
- 扫描超时自动停止并切回 `.idle`

### 4.2 连接与重连

| 方法 | 说明 |
|------|------|
| `connect(_ device:)` | 连接指定设备，开启自动重连 |
| `disconnect()` | 主动断开，不触发重连 |
| `readValue(role:)` | 读取指定角色的特征值 |

**自动重连策略（指数退避）：**

```
第 1 次重连：延迟 1s
第 2 次重连：延迟 2s
第 3 次重连：延迟 4s
第 4 次重连：延迟 8s
第 5 次重连：延迟 16s（上限）
超过最大次数 → 标记 failed
```

- 主动断开（`shouldAutoReconnect = false`）不触发重连
- 异常断开（`error != nil`）触发重连
- 重连前检查 `peripheral.state == .disconnected`

### 4.3 数据传输

提供两种写入接口，互斥执行（同一时间只允许一个传输）：

#### sendRaw — 裸数据写入

```
特点：不加应用层包头，不等待 ACK，不重试
适用：简短调试命令、外设不支持 App 层协议时
模式：fireAndForget
```

#### sendReliableData — 可靠传输

```
特点：应用层帧头 + CRC32 + ACK 窗口 + 超时重试
适用：文件传输、OTA 固件升级、关键配置命令
模式：applicationAck

参数：
├── role: 写入特征角色（默认 .dataWrite）
├── ackWindow: 6（同时在途未确认的包数）
├── maxRetries: 3（单包最大重试次数）
├── ackTimeout: 1.5s（等待 ACK 的超时）
├── useApplicationFrame: true（是否加帧头）
└── supportsResume: false（是否支持断点续传，默认关闭）
```

### 4.4 传输流程图

```
sendReliableData(data)
    │
    ├── 检查是否已有传输进行中
    ├── 检查特征是否就绪
    ├── 检查写入方式是否支持
    ├── 检查 MTU 是否足够
    │
    ▼
按 MTU 拆分为帧 → 编码（加头+CRC） → 创建 ActiveTransfer
    │
    ▼
flushActiveTransfer() ←─────────────────────────┐
    │                                            │
    ├── canSendNext? ──否──→ 等待               │
    │   │                                        │
    │   是                                       │
    │   ▼                                        │
    ├── 写入 peripheral.writeValue               │
    │   │                                        │
    │   ├── applicationAck?                      │
    │   │   ├── 是 → 注册 ACK 超时定时器          │
    │   │   │       │                            │
    │   │   │       ├── 收到 ACK → markAcked ────┘
    │   │   │       │              │
    │   │   │       │              ├── 全部 ACK？ → 传输完成通知
    │   │   │       │              └── 否 → flushActiveTransfer ──→ (循环)
    │   │   │       │
    │   │   │       └── 超时 → retry(sequence)
    │   │   │           ├── 重试次数 < max？ → 重新入队 → flush ──→ (循环)
    │   │   │           └── 超过 → 取消传输，通知失败
    │   │   │
    │   │   └── 否 (fireAndForget) → 直接 markAcked
    │   │
    │   └── canSendWriteWithoutResponse == false? → 返回，等待回调
    │                                                   │
    │                                   peripheralIsReady ──→ flush ──→ (循环)
    │
    └── 全部 ACK？ → 传输完成，通知 delegate
```

### 4.5 状态恢复

当 App 被系统杀掉后重新启动时，可以恢复之前的蓝牙连接：

1. **Info.plist** 中配置 `UIBackgroundModes → bluetooth-central`
2. **初始化时**传入 `CBCentralManagerOptionRestoreIdentifierKey`
3. **系统恢复时**回调 `willRestoreState`，自动重新发现服务和特征

### 4.6 断点续传（可选，默认关闭）

通过 `BluetoothTransferOptions.supportsResume` 控制，默认 `false`：

```
传输中断连
    │
    ├── supportsResume = false → 直接取消传输（默认行为）
    │
    └── supportsResume = true
         ├── 保存上下文（原始 Data + 已确认 offset + 配置）
         ├── 通知 delegate: didPauseTransfer(id, ackedOffset)
         ├── 等待自动重连...
         │
         └── 重连成功 + 特征就绪
              ├── 从 ackedOffset 创建新 ActiveTransfer
              ├── 通知 delegate: didResumeTransfer(id, fromOffset)
              └── 自动继续传输剩余部分
```

使用方式：

```swift
manager.sendReliableData(fileData, options: BluetoothTransferOptions(
    role: .dataWrite,
    reliability: .applicationAck,
    useApplicationFrame: true,
    supportsResume: true  // ← 开启断点续传
))
```

> 注意：开启续传时原始数据会保留在内存中直到传输完成或取消。

### 4.7 大文件传输优化

本模块针对大文件传输（如 OTA 固件升级）做了三项优化：

#### 4.7.1 懒加载帧生成

`ActiveTransfer` 不再预创建全部帧，而是按需生成：

```
旧方式（100MB）：makeDataFrames → 61万个帧 → 61万个 encoded Data → 61万个 Packet
                内存峰值 ≈ 420MB

新方式（100MB）：只存原始 Data，nextPacket() 时按索引切片+编码
                内存峰值 ≈ 100MB + 6个在途包（ACK窗口=6）
```

#### 4.7.2 进度回调节流

每收到一个 ACK 只更新内部计数，进度回调最少间隔 100ms 才通知一次：

```
旧方式：每包回调一次 → 61万次 → 卡顿
新方式：100ms 节流 → ~600 次回调 → 流畅
（传输完成时立即通知，不受节流限制）
```

#### 4.7.3 MTU 自动协商

iOS 上 CoreBluetooth 在连接时自动与外设协商 MTU 到双方支持的最大值，无需手动请求。`maximumWriteValueLength(for:)` 返回协商后的实际值，`sendReliableData` 内部已用它动态计算每帧 payload 大小：

| MTU | 每帧 Payload | 100MB 帧数 |
|-----|------------|-----------|
| 185（默认） | ~160 B | ~655,360 |
| 247（BLE 5.0） | ~222 B | ~471,859 |
| 517（BLE 4.2+） | ~492 B | ~212,868 |

---

## 五、线程模型

```
┌─────────────────────────────────────────────────┐
│              蓝牙专用串行队列                       │
│   label: "com.testdemo.bluetooth.manager"        │
│                                                  │
│   • 所有 CoreBluetooth 调用                       │
│   • 所有状态变更                                   │
│   • 所有定时器（扫描/连接/ACK 超时）                 │
│   • 传输队列调度                                   │
│                                                  │
│   connectionState 用 NSLock 保护跨线程读取          │
├─────────────────────────────────────────────────┤
│                  主线程                           │
│                                                  │
│   • delegate 回调（通过 DispatchQueue.main.async）│
│   • delegateTable 注册/移除                      │
│   • UI 更新                                      │
└─────────────────────────────────────────────────┘
```

---

## 六、Delegate 协议

通过弱引用 delegate 表支持多个监听者，所有方法都有默认空实现：

```swift
protocol BluetoothManagerDelegate: AnyObject {
    // 蓝牙适配器状态
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: CBManagerState)
    
    // 连接状态机变化
    func bluetoothManager(_ manager: BluetoothManager, didChangeConnectionState state: BluetoothConnectionState)
    
    // 扫描发现设备
    func bluetoothManager(_ manager: BluetoothManager, didDiscover devices: [BluetoothDevice])
    
    // 连接成功
    func bluetoothManager(_ manager: BluetoothManager, didConnect device: BluetoothDevice)
    
    // 连接断开
    func bluetoothManager(_ manager: BluetoothManager, didDisconnect device: BluetoothDevice?, error: Error?)
    
    // 特征角色就绪
    func bluetoothManager(_ manager: BluetoothManager, didUpdateReady roles: Set<BluetoothCharacteristicRole>)
    
    // 收到数据
    func bluetoothManager(_ manager: BluetoothManager, didReceive data: Data, role: BluetoothCharacteristicRole?)
    
    // 传输进度
    func bluetoothManager(_ manager: BluetoothManager, didUpdateTransfer progress: BluetoothPacketProgress)
    
    // 传输完成
    func bluetoothManager(_ manager: BluetoothManager, didCompleteTransfer id: UUID)
    
    // 运行时指标
    func bluetoothManager(_ manager: BluetoothManager, didUpdateMetrics metrics: BluetoothMetricSnapshot)
    
    // 发生错误
    func bluetoothManager(_ manager: BluetoothManager, didFail error: Error)
    
    // 传输因断连被暂停（仅当 supportsResume = true 时触发）
    func bluetoothManager(_ manager: BluetoothManager, didPauseTransfer id: UUID, ackedOffset: Int)
    
    // 传输从断点恢复（重连后自动恢复）
    func bluetoothManager(_ manager: BluetoothManager, didResumeTransfer id: UUID, fromOffset: Int)
}
```

使用方式：

```swift
class MyViewController: UIViewController, BluetoothManagerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        BluetoothManager.shared.addDelegate(self)
    }
    
    deinit {
        BluetoothManager.shared.removeDelegate(self)
    }
}
```

---

## 七、错误类型

```swift
enum BluetoothError: LocalizedError {
    case bluetoothUnavailable(CBManagerState)      // 蓝牙不可用
    case peripheralNotFound                        // 找不到外设
    case characteristicNotReady(BluetoothCharacteristicRole)  // 特征未就绪
    case transferInProgress                        // 已有传输进行中
    case connectTimeout                            // 连接超时
    case ackTimeout(UInt32)                        // ACK 超时
    case unsupportedWriteType                      // 不支持写入
    case mtuTooSmall(Int)                          // MTU 太小
}
```

---

## 八、Demo 使用指南

### 8.1 界面布局

```
┌─────────────────────┐
│  连接与状态            │  ← 蓝牙状态 / 已连接设备 / 特征就绪 / 传输进度
├─────────────────────┤
│  操作                 │  ← 扫描 / 停止扫描 / 断开 / 发命令 / 发大数据
├─────────────────────┤
│  附近设备             │  ← 扫描结果列表，点击行可连接
├─────────────────────┤
│  优化日志             │  ← 实时显示运行日志
└─────────────────────┘
```

### 8.2 按钮状态

| 按钮 | 启用条件 |
|------|---------|
| 扫描 | 未扫描 && 未连接 |
| 停止扫描 | 正在扫描 |
| 断开 | 已连接 |
| 发命令 | 特征就绪 |
| 发大数据 | 特征就绪 |

### 8.3 典型使用流程

```swift
// 1. 获取单例
let manager = BluetoothManager.shared

// 2. 注册监听
manager.addDelegate(self)

// 3. 配置参数
manager.update(configuration: BluetoothTransferConfiguration(
    profile: .genericDemo,    // Demo 模式
    scanTimeout: 12,           // 扫描 12 秒超时
    connectTimeout: 8,         // 连接 8 秒超时
    reconnectMaxAttempts: 5,   // 最多重连 5 次
    reconnectBaseDelay: 1      // 基础延迟 1 秒
))

// 4. 开始扫描
manager.startScan()

// 5. 连接设备（在 didDiscover 回调中选择）
manager.connect(device)

// 6. 发送数据（在 didUpdateReady 回调后）
manager.sendRaw(Data("PING".utf8), role: .commandWrite)          // 裸数据

// 可靠传输（默认不支持断点续传）
manager.sendReliableData(fileData, options: BluetoothTransferOptions(
    role: .dataWrite,
    reliability: .applicationAck,
    ackWindow: 6,
    maxRetries: 3,
    ackTimeout: 1.5,
    useApplicationFrame: true
))

// 可靠传输 + 断点续传（大文件推荐）
manager.sendReliableData(otaFirmwareData, options: BluetoothTransferOptions(
    role: .dataWrite,
    reliability: .applicationAck,
    ackWindow: 6,
    maxRetries: 3,
    ackTimeout: 1.5,
    useApplicationFrame: true,
    supportsResume: true  // 断连后自动从断点恢复
))

// 7. 读取数据
manager.readValue(role: .read)

// 8. 断开
manager.disconnect()
```

---

## 九、生产环境接入指南

### 9.1 替换 genericDemo 为真实设备画像

```swift
let profile = BluetoothDeviceProfile(
    name: "MyDevice",
    scanServiceUUIDs: [CBUUID(string: "XXXX")],       // 替换为真实 service UUID
    serviceUUIDs: [CBUUID(string: "XXXX")],
    characteristics: [
        BluetoothCharacteristicProfile(
            role: .commandWrite,
            serviceUUID: CBUUID(string: "XXXX"),
            characteristicUUID: CBUUID(string: "XXXX"),
            enableNotify: false,
            preferredWriteType: .withoutResponse
        ),
        BluetoothCharacteristicProfile(
            role: .notify,
            serviceUUID: CBUUID(string: "XXXX"),
            characteristicUUID: CBUUID(string: "XXXX"),
            enableNotify: true,
            preferredWriteType: .withoutResponse
        ),
        // ... 更多特征
    ]
)

manager.update(configuration: BluetoothTransferConfiguration(
    profile: profile,
    // ... 其他参数
))
```

### 9.2 外设固件配合要求

如果使用 `sendReliableData`（applicationAck 模式），外设固件需要：

1. **解析帧头**：按 22 字节头部解析 magic、version、type、sequence、offset、totalLength、payloadLen、crc32
2. **校验 CRC32**：使用相同的多项式 `0xEDB88320` 校验 payload
3. **回传 ACK 帧**：处理完一帧后，通过 notify 特征回传一个 `.ack` 类型帧，`sequence` 字段填入收到的帧序号
4. ACK 帧格式：使用 `BluetoothProtocolCodec.makeAck(sequence:offset:totalLength:)` 编码后写入

如果外设不回 ACK，传输会在 `ackTimeout`（默认 1.5s）后触发重试，超过 `maxRetries`（默认 3 次）后报错。

### 9.3 后台蓝牙要求

- 在 Info.plist 中配置 `UIBackgroundModes → bluetooth-central`
- 状态恢复标识符在 `BluetoothTransferConfiguration.restorationIdentifier` 中设置
- App 被系统杀掉后重启，`willRestoreState` 会自动恢复连接并重新发现服务
