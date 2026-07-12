//
//  BluetoothManager.swift
//  TestDemo01
//
//  Created by Codex on 2026/7/11.
//

/// 蓝牙核心管理器，封装了 CoreBluetooth 的完整通信流程：
///
/// **主要职责：**
/// 1. 扫描 —— 按 service UUID 过滤扫描附近 BLE 设备
/// 2. 连接 —— 连接设备、发现服务和特征、自动重连（指数退避）
/// 3. 传输 —— 提供两种写入接口：
///    - `sendRaw`: 裸数据写入，不加应用层包头，适合简单调试
///    - `sendReliableData`: 可靠传输，含包头+CRC+ACK窗口+超时重试
/// 4. 状态管理 —— 维护连接状态机，通过 weak delegate 模式通知外部
/// 5. 指标统计 —— 记录连接耗时、收发字节数、重连次数等
///
/// **线程模型：**
/// 所有蓝牙操作在专用串行队列 `queue` 上执行，回调统一切回主线程。
///
/// **关键设计决策：**
/// - delegate 使用 NSHashTable.weakObjects 弱引用，避免循环引用
/// - 连接超时、扫描超时、ACK 超时均通过 DispatchWorkItem 管理
/// - 应用层协议帧格式见 BluetoothTransferProtocol.swift

import CoreBluetooth
import Foundation

// MARK: - 数据模型

/// 扫描发现的或已连接的蓝牙设备模型
struct BluetoothDevice: Equatable {
    /// 系统分配的唯一标识符
    let identifier: UUID
    /// 设备名称
    let name: String
    /// 信号强度（dBm），值越接近 0 信号越强
    let rssi: Int
    /// CoreBluetooth 外设对象
    let peripheral: CBPeripheral

    /// 只通过 identifier 判等，避免同一设备因 RSSI 变化而重复
    static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

// MARK: - 传输配置

/// 蓝牙传输全局配置
struct BluetoothTransferConfiguration {
    /// 设备协议画像（扫描过滤 UUID、服务/特征定义等）
    var profile: BluetoothDeviceProfile = .genericDemo
    /// 扫描超时时间（秒），超时后自动停止扫描
    var scanTimeout: TimeInterval = 10
    /// 连接超时时间（秒），超时后取消连接并报错
    var connectTimeout: TimeInterval = 8
    /// 最大重连次数
    var reconnectMaxAttempts: Int = 5
    /// 重连基础延迟（秒），实际延迟按指数退避：baseDelay × 2^(attempt-1)
    var reconnectBaseDelay: TimeInterval = 1
    /// 状态恢复标识符，用于 App 被系统杀掉后恢复蓝牙连接
    var restorationIdentifier: String = "com.testdemo.bluetooth.central.restore"
}

// MARK: - Delegate 协议

/// 蓝牙管理器的委托协议，通过 weak 方式持有，支持多对象同时监听。
/// 所有方法都有默认空实现，使用方只需实现关心的回调。
protocol BluetoothManagerDelegate: AnyObject {
    /// 蓝牙适配器状态变化（如开关蓝牙、授权变更）
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: CBManagerState)
    /// 连接状态机变化（如 scanning → connecting → ready → disconnected）
    func bluetoothManager(_ manager: BluetoothManager, didChangeConnectionState state: BluetoothConnectionState)
    /// 发现新设备或设备信息更新
    func bluetoothManager(_ manager: BluetoothManager, didDiscover devices: [BluetoothDevice])
    /// 连接成功
    func bluetoothManager(_ manager: BluetoothManager, didConnect device: BluetoothDevice)
    /// 连接断开
    func bluetoothManager(_ manager: BluetoothManager, didDisconnect device: BluetoothDevice?, error: Error?)
    /// 特征角色就绪，可以开始收发数据
    func bluetoothManager(_ manager: BluetoothManager, didUpdateReady roles: Set<BluetoothCharacteristicRole>)
    /// 收到外设发来的数据
    func bluetoothManager(_ manager: BluetoothManager, didReceive data: Data, role: BluetoothCharacteristicRole?)
    /// 传输进度更新
    func bluetoothManager(_ manager: BluetoothManager, didUpdateTransfer progress: BluetoothPacketProgress)
    /// 整个传输完成
    func bluetoothManager(_ manager: BluetoothManager, didCompleteTransfer id: UUID)
    /// 运行时指标更新（连接耗时、收发字节数等）
    func bluetoothManager(_ manager: BluetoothManager, didUpdateMetrics metrics: BluetoothMetricSnapshot)
    /// 发生错误
    func bluetoothManager(_ manager: BluetoothManager, didFail error: Error)
    /// 传输因断连被暂停（仅当 supportsResume = true 时触发）
    func bluetoothManager(_ manager: BluetoothManager, didPauseTransfer id: UUID, ackedOffset: Int)
    /// 传输从断点恢复（重连后自动恢复）
    func bluetoothManager(_ manager: BluetoothManager, didResumeTransfer id: UUID, fromOffset: Int)
}

/// 协议方法的默认空实现，让使用方可以只实现关心的回调
extension BluetoothManagerDelegate {
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: CBManagerState) {}
    func bluetoothManager(_ manager: BluetoothManager, didChangeConnectionState state: BluetoothConnectionState) {}
    func bluetoothManager(_ manager: BluetoothManager, didDiscover devices: [BluetoothDevice]) {}
    func bluetoothManager(_ manager: BluetoothManager, didConnect device: BluetoothDevice) {}
    func bluetoothManager(_ manager: BluetoothManager, didDisconnect device: BluetoothDevice?, error: Error?) {}
    func bluetoothManager(_ manager: BluetoothManager, didUpdateReady roles: Set<BluetoothCharacteristicRole>) {}
    func bluetoothManager(_ manager: BluetoothManager, didReceive data: Data, role: BluetoothCharacteristicRole?) {}
    func bluetoothManager(_ manager: BluetoothManager, didUpdateTransfer progress: BluetoothPacketProgress) {}
    func bluetoothManager(_ manager: BluetoothManager, didCompleteTransfer id: UUID) {}
    func bluetoothManager(_ manager: BluetoothManager, didUpdateMetrics metrics: BluetoothMetricSnapshot) {}
    func bluetoothManager(_ manager: BluetoothManager, didFail error: Error) {}
    func bluetoothManager(_ manager: BluetoothManager, didPauseTransfer id: UUID, ackedOffset: Int) {}
    func bluetoothManager(_ manager: BluetoothManager, didResumeTransfer id: UUID, fromOffset: Int) {}
}

// MARK: - 错误类型

/// 蓝牙操作可能产生的错误
enum BluetoothError: LocalizedError {
    /// 蓝牙不可用（如关闭、未授权等，附带当前状态）
    case bluetoothUnavailable(CBManagerState)
    /// 找不到指定外设
    case peripheralNotFound
    /// 指定角色的特征尚未就绪
    case characteristicNotReady(BluetoothCharacteristicRole)
    /// 已有传输正在进行，无法同时发起第二个
    case transferInProgress
    /// 连接超时
    case connectTimeout
    /// 数据包 ACK 超时（附带超时的序号）
    case ackTimeout(UInt32)
    /// 特征不支持任何写入方式
    case unsupportedWriteType
    /// 当前 MTU 太小，无法容纳应用层帧头
    case mtuTooSmall(Int)

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable(let state):
            return "Bluetooth is unavailable: \(state)"
        case .peripheralNotFound:
            return "Bluetooth peripheral was not found."
        case .characteristicNotReady(let role):
            return "Bluetooth characteristic is not ready: \(role.rawValue)"
        case .transferInProgress:
            return "Another Bluetooth transfer is still running."
        case .connectTimeout:
            return "Bluetooth connection timed out."
        case .ackTimeout(let sequence):
            return "Bluetooth packet ACK timed out: \(sequence)"
        case .unsupportedWriteType:
            return "Characteristic does not support a valid write type."
        case .mtuTooSmall(let maximumWriteLength):
            return "Current BLE MTU is too small for application frame: \(maximumWriteLength)"
        }
    }
}

// MARK: - BluetoothManager

/// 蓝牙核心管理器（单例）
final class BluetoothManager: NSObject {

    // MARK: 单例

    /// 全局单例
    static let shared = BluetoothManager()

    // MARK: 内部状态

    /// 蓝牙操作的专用串行队列，所有 CoreBluetooth 调用都在此队列上
    private let queue = DispatchQueue(label: "com.testdemo.bluetooth.manager")
    /// 弱引用 delegate 表，支持多个监听者，自动释放
    private let delegateTable = NSHashTable<AnyObject>.weakObjects()
    /// CoreBluetooth 中央管理器
    private var centralManager: CBCentralManager!

    /// 当前传输配置
    private var configuration = BluetoothTransferConfiguration()
    /// 已发现的设备字典（key 为设备 UUID，便于去重和更新）
    private var discoveredMap: [UUID: BluetoothDevice] = [:]
    /// 当前已连接的外设
    private var connectedPeripheral: CBPeripheral?
    /// 当前已连接的设备模型
    private var connectedDevice: BluetoothDevice?
    /// 角色到特征的映射（如 .commandWrite → CBCharacteristic）
    private var characteristicsByRole: [BluetoothCharacteristicRole: CBCharacteristic] = [:]
    /// 特征 UUID 到角色的反向映射，收到数据时用于判断来源
    private var characteristicRolesByUUID: [CBUUID: BluetoothCharacteristicRole] = [:]
    /// 是否允许自动重连（主动断开时设为 false）
    private var shouldAutoReconnect = true
    /// 当前已尝试的重连次数
    private var reconnectAttempts = 0
    /// 延迟重连的 DispatchWorkItem
    private var pendingReconnectWorkItem: DispatchWorkItem?
    /// 连接超时的 DispatchWorkItem
    private var connectTimeoutWorkItem: DispatchWorkItem?
    /// 扫描超时的 DispatchWorkItem
    private var scanTimeoutWorkItem: DispatchWorkItem?
    /// 当前正在进行的传输
    private var activeTransfer: ActiveTransfer?
    /// 运行时指标
    private var metrics = BluetoothMetricSnapshot()

    /// 断点续传上下文（断连时保存，重连后恢复）
    private var pendingResume: (data: Data, maxPayloadLength: Int, options: BluetoothTransferOptions, ackedOffset: Int, transferId: UUID)?
    /// 进度回调节流时间戳
    private var lastProgressNotifyTime: Date?

    /// 连接状态机线程安全锁
    private let stateLock = NSLock()
    /// 连接状态机（内部存储）
    private var _connectionState: BluetoothConnectionState = .idle
    /// 连接状态机（线程安全读取），变化时自动通知 delegate
    private(set) var connectionState: BluetoothConnectionState {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _connectionState
        }
        set {
            stateLock.lock()
            _connectionState = newValue
            stateLock.unlock()
            notifyConnectionState(newValue)
        }
    }

    // MARK: 只读属性

    /// 蓝牙适配器当前状态
    var state: CBManagerState {
        centralManager.state
    }

    /// 当前已连接的设备
    var currentDevice: BluetoothDevice? {
        connectedDevice
    }

    // MARK: 初始化

    /// 私有初始化，保证单例
    private override init() {
        super.init()
        // 在专用队列上创建 CBCentralManager，启用状态恢复以支持 App 被系统杀掉后恢复连接
        // 需要在 Info.plist 中配置 UIBackgroundModes → bluetooth-central
        centralManager = CBCentralManager(
            delegate: self,
            queue: queue,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: configuration.restorationIdentifier
            ]
        )
    }

    // MARK: - Delegate 管理

    /// 添加监听者（弱引用，无需手动移除，但建议在 deinit 中移除）
    /// - Note: 在主线程调用时同步注册，避免错过即时事件
    func addDelegate(_ delegate: BluetoothManagerDelegate) {
        if Thread.isMainThread {
            delegateTable.add(delegate)
        } else {
            DispatchQueue.main.async { self.delegateTable.add(delegate) }
        }
    }

    /// 移除监听者
    func removeDelegate(_ delegate: BluetoothManagerDelegate) {
        if Thread.isMainThread {
            delegateTable.remove(delegate)
        } else {
            DispatchQueue.main.async { self.delegateTable.remove(delegate) }
        }
    }

    // MARK: - 配置

    /// 更新传输配置（线程安全）
    func update(configuration: BluetoothTransferConfiguration) {
        queue.async {
            self.configuration = configuration
        }
    }

    // MARK: - 扫描

    /// 开始扫描附近 BLE 设备
    /// - Parameters:
    ///   - serviceUUIDs: 要过滤的 service UUID，nil 则使用配置中的 profile
    ///   - timeout: 扫描超时时间，nil 则使用配置中的 scanTimeout
    func startScan(serviceUUIDs: [CBUUID]? = nil, timeout: TimeInterval? = nil) {
        queue.async {
            // 蓝牙必须处于 poweredOn 状态
            guard self.centralManager.state == .poweredOn else {
                self.notifyFailure(BluetoothError.bluetoothUnavailable(self.centralManager.state))
                return
            }

            // 清空之前的扫描结果
            self.discoveredMap.removeAll()
            self.connectionState = .scanning
            // 使用传入的 UUID 或配置中的 profile UUID
            let targetServices = serviceUUIDs ?? self.configuration.profile.scanServiceUUIDs
            self.centralManager.scanForPeripherals(
                withServices: targetServices,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
            // 设置扫描超时
            self.scheduleScanTimeout(timeout ?? self.configuration.scanTimeout)
        }
    }

    /// 停止扫描
    func stopScan() {
        queue.async {
            self.centralManager.stopScan()
            self.scanTimeoutWorkItem?.cancel()
            self.scanTimeoutWorkItem = nil
            // 如果当前是扫描状态，切回空闲
            if case .scanning = self.connectionState {
                self.connectionState = .idle
            }
        }
    }

    /// 从系统缓存中检索已知外设（之前连接过的设备）
    /// - Parameter identifiers: 之前保存的设备 UUID 列表
    func retrieveKnownPeripherals(identifiers: [UUID]) {
        queue.async {
            let peripherals = self.centralManager.retrievePeripherals(withIdentifiers: identifiers)
            let devices = peripherals.map {
                BluetoothDevice(
                    identifier: $0.identifier,
                    name: $0.name ?? "Cached Device",
                    rssi: 0,
                    peripheral: $0
                )
            }
            devices.forEach { self.discoveredMap[$0.identifier] = $0 }
            self.notifyDiscoveredDevices()
        }
    }

    /// 检索当前已通过系统连接的外设（如其他 App 连接的设备）
    /// - Parameter serviceUUIDs: 按 service UUID 过滤
    func retrieveConnectedPeripherals(serviceUUIDs: [CBUUID]) {
        queue.async {
            let peripherals = self.centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
            let devices = peripherals.map {
                BluetoothDevice(
                    identifier: $0.identifier,
                    name: $0.name ?? "Connected Device",
                    rssi: 0,
                    peripheral: $0
                )
            }
            devices.forEach { self.discoveredMap[$0.identifier] = $0 }
            self.notifyDiscoveredDevices()
        }
    }

    // MARK: - 连接

    /// 连接指定设备，开启自动重连
    func connect(_ device: BluetoothDevice) {
        queue.async {
            self.shouldAutoReconnect = true
            self.reconnectAttempts = 0
            self.connectInternal(device.peripheral)
        }
    }

    /// 断开当前连接（不触发自动重连）
    func disconnect() {
        queue.async {
            self.shouldAutoReconnect = false
            // 取消所有待处理的延迟操作
            self.pendingReconnectWorkItem?.cancel()
            self.connectTimeoutWorkItem?.cancel()
            // 取消正在进行的传输
            self.cancelActiveTransfer()
            guard let peripheral = self.connectedPeripheral else {
                self.connectionState = .idle
                return
            }
            self.connectionState = .disconnecting(peripheral.identifier)
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - 数据写入

    /// 原始写入接口，适合临时调试或外设协议不支持 App 层包头的情况。
    /// 生产中的文件/OTA/关键命令建议优先使用 sendReliableData。
    ///
    /// - Parameters:
    ///   - data: 要发送的原始数据
    ///   - role: 写入特征角色，默认 .commandWrite
    ///   - writeType: 写入方式，nil 则自动选择
    func sendRaw(
        _ data: Data,
        role: BluetoothCharacteristicRole = .commandWrite,
        writeType: CBCharacteristicWriteType? = nil
    ) {
        queue.async {
            // 不允许并发传输
            guard self.activeTransfer == nil else {
                self.notifyFailure(BluetoothError.transferInProgress)
                return
            }

            // 检查目标特征是否就绪
            guard let characteristic = self.characteristicsByRole[role] else {
                self.notifyFailure(BluetoothError.characteristicNotReady(role))
                return
            }

            // 选择写入方式
            guard let type = self.bestWriteType(for: characteristic, preferred: writeType) else {
                self.notifyFailure(BluetoothError.unsupportedWriteType)
                return
            }

            // 按 MTU 分块（ActiveTransfer 内部懒加载，不会一次性创建所有帧）
            let maxLength = max(1, self.connectedPeripheral?.maximumWriteValueLength(for: type) ?? 20)
            // 构建传输对象（fireAndForget 模式，不加应用层帧）
            self.activeTransfer = ActiveTransfer(
                data: data,
                maxPayloadLength: maxLength,
                options: BluetoothTransferOptions(
                    role: role,
                    reliability: .fireAndForget,
                    maxPayloadLength: maxLength,
                    writeType: type,
                    useApplicationFrame: false
                )
            )
            self.flushActiveTransfer()
        }
    }

    /// 可靠传输接口：App 层包头 + CRC + ACK 窗口 + 超时重试。
    /// 注意：外设固件需要按 BluetoothProtocolCodec 的格式回 ACK，否则会触发超时重试。
    ///
    /// - Parameters:
    ///   - data: 要发送的数据
    ///   - options: 传输配置（角色、可靠性、窗口大小、重试次数等）
    func sendReliableData(_ data: Data, options: BluetoothTransferOptions = BluetoothTransferOptions()) {
        queue.async {
            // 不允许并发传输
            guard self.activeTransfer == nil else {
                self.notifyFailure(BluetoothError.transferInProgress)
                return
            }

            // 检查目标特征是否就绪
            guard let characteristic = self.characteristicsByRole[options.role] else {
                self.notifyFailure(BluetoothError.characteristicNotReady(options.role))
                return
            }

            // 选择写入方式
            guard let type = self.bestWriteType(for: characteristic, preferred: options.writeType) else {
                self.notifyFailure(BluetoothError.unsupportedWriteType)
                return
            }

            // 计算 MTU 和 payload 长度
            let maximumWriteLength = max(1, self.connectedPeripheral?.maximumWriteValueLength(for: type) ?? 20)
            let headerLength = options.useApplicationFrame ? BluetoothProtocolFrame.headerLength : 0
            // MTU 必须能容纳头部
            guard maximumWriteLength > headerLength else {
                self.notifyFailure(BluetoothError.mtuTooSmall(maximumWriteLength))
                return
            }
            // payload 长度 = min(配置值, MTU - 头部)
            let payloadLength = max(1, min(options.maxPayloadLength ?? maximumWriteLength - headerLength, maximumWriteLength - headerLength))

            // 更新配置中的实际写入方式和 payload 长度
            var resolvedOptions = options
            resolvedOptions.writeType = type
            resolvedOptions.maxPayloadLength = payloadLength

            // ActiveTransfer 内部懒加载帧，不会一次性创建全部帧对象
            self.activeTransfer = ActiveTransfer(
                data: data,
                maxPayloadLength: payloadLength,
                options: resolvedOptions
            )
            self.flushActiveTransfer()
        }
    }

    /// 读取指定角色的特征值（异步操作，结果通过 didReceive 回调返回）
    /// - Parameter role: 要读取的特征角色，默认 .read
    func readValue(role: BluetoothCharacteristicRole = .read) {
        queue.async {
            guard let characteristic = self.characteristicsByRole[role] else {
                self.notifyFailure(BluetoothError.characteristicNotReady(role))
                return
            }
            self.connectedPeripheral?.readValue(for: characteristic)
        }
    }

    // MARK: - 内部：连接流程

    /// 实际连接外设的内部方法
    private func connectInternal(_ peripheral: CBPeripheral) {
        // 先停止扫描，避免扫描和连接抢占资源
        centralManager.stopScan()
        scanTimeoutWorkItem?.cancel()
        connectTimeoutWorkItem?.cancel()
        // 取消正在进行的传输
        cancelActiveTransfer()
        // 清空特征缓存
        characteristicsByRole.removeAll()
        characteristicRolesByUUID.removeAll()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        // 记录连接开始时间
        metrics.connectStartedAt = Date()
        metrics.readyAt = nil
        connectionState = .connecting(peripheral.identifier)
        // 发起连接，设置断开提醒选项
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ])
        // 设置连接超时
        scheduleConnectTimeout(peripheral)
    }

    /// 设置扫描超时定时器
    private func scheduleScanTimeout(_ timeout: TimeInterval) {
        scanTimeoutWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.centralManager.stopScan()
            // 扫描超时后切回空闲状态
            if case .scanning = self?.connectionState {
                self?.connectionState = .idle
            }
        }
        scanTimeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    /// 设置连接超时定时器，超时后取消连接并报错
    private func scheduleConnectTimeout(_ peripheral: CBPeripheral) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, peripheral.state == .connecting else { return }
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.connectionState = .failed(BluetoothError.connectTimeout.localizedDescription)
            self.notifyFailure(BluetoothError.connectTimeout)
        }
        connectTimeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + configuration.connectTimeout, execute: workItem)
    }

    /// 触发自动重连（指数退避策略）
    /// 延迟序列：1s → 2s → 4s → 8s → 16s（上限 16s）
    private func scheduleReconnect() {
        // 检查是否允许重连、外设已断开、且未超过最大次数
        guard shouldAutoReconnect,
              let peripheral = connectedPeripheral,
              peripheral.state == .disconnected,
              reconnectAttempts < configuration.reconnectMaxAttempts else { return }

        reconnectAttempts += 1
        metrics.reconnectAttempts = reconnectAttempts
        // 指数退避：baseDelay × 2^(attempt-1)，上限 16 秒
        let delay = min(pow(2, Double(reconnectAttempts - 1)) * configuration.reconnectBaseDelay, 16)
        connectionState = .reconnecting(peripheral.identifier, attempt: reconnectAttempts)
        notifyMetrics()

        // 延迟后重新连接
        pendingReconnectWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.connectInternal(peripheral)
        }
        pendingReconnectWorkItem = workItem
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    // MARK: - 内部：传输流程

    /// 刷新传输队列：尽可能多地发送待发数据包
    private func flushActiveTransfer() {
        guard let transfer = activeTransfer else { return }
        guard let peripheral = connectedPeripheral,
              let characteristic = characteristicsByRole[transfer.options.role],
              let writeType = transfer.options.writeType else {
            notifyFailure(BluetoothError.characteristicNotReady(transfer.options.role))
            return
        }

        // 在窗口和队列限制内，尽可能多地写入数据包
        while transfer.canSendNext {
            // .withoutResponse 模式需要检查底层是否可写
            if writeType == .withoutResponse, !peripheral.canSendWriteWithoutResponse {
                return
            }

            guard let packet = transfer.nextPacket() else { break }
            // 写入数据到蓝牙特征
            peripheral.writeValue(packet.data, for: characteristic, type: writeType)
            // 更新指标
            metrics.transmittedBytes += packet.payloadSize
            notifyProgress()
            notifyMetrics()

            if transfer.options.reliability == .applicationAck {
                // 可靠传输：等待 ACK，设置超时
                scheduleAckTimeout(sequence: packet.sequence, transferID: transfer.id)
            } else {
                // fireAndForget：直接标记为已确认
                transfer.markAcked(sequence: packet.sequence)
            }
        }

        // 检查是否所有包都已确认，传输完成
        completeTransferIfNeeded()
    }

    /// 设置 ACK 超时定时器
    private func scheduleAckTimeout(sequence: UInt32, transferID: UUID) {
        guard let transfer = activeTransfer else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.handleAckTimeout(sequence: sequence, transferID: transferID)
        }
        transfer.registerTimeout(workItem, sequence: sequence)
        queue.asyncAfter(deadline: .now() + transfer.options.ackTimeout, execute: workItem)
    }

    /// 处理 ACK 超时：重试或报错
    private func handleAckTimeout(sequence: UInt32, transferID: UUID) {
        guard let transfer = activeTransfer, transfer.id == transferID else { return }
        // 尝试重试该数据包
        guard transfer.retry(sequence: sequence) else {
            // 超过最大重试次数，取消传输并报错
            cancelActiveTransfer()
            notifyFailure(BluetoothError.ackTimeout(sequence))
            return
        }
        // 重新刷新传输队列
        flushActiveTransfer()
    }

    /// 处理收到的应用层帧（如 ACK）
    /// - Parameter frame: 解码后的帧
    /// - Returns: true 表示已处理（是 ACK 帧），false 表示是普通数据帧，交给上层
    private func handleApplicationFrame(_ frame: BluetoothProtocolFrame) -> Bool {
        switch frame.type {
        case .ack:
            // 收到 ACK：标记对应序号的包为已确认
            activeTransfer?.markAcked(sequence: frame.sequence)
            // 继续发送后续包
            flushActiveTransfer()
            // 检查是否完成
            completeTransferIfNeeded()
            return true
        case .data, .complete, .resumeRequest:
            // 非 ACK 帧，不在此处理
            return false
        }
    }

    /// 检查传输是否完成，完成则通知 delegate
    private func completeTransferIfNeeded() {
        guard let transfer = activeTransfer, transfer.isComplete else { return }
        let id = transfer.id
        activeTransfer = nil
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didCompleteTransfer: id) }
        }
    }

    /// 取消当前传输，清理所有超时定时器
    private func cancelActiveTransfer() {
        activeTransfer?.cancelTimeouts()
        activeTransfer = nil
    }

    // MARK: - 内部：写入方式选择

    /// 根据特征属性和偏好选择最佳写入方式
    /// 优先级：偏好 → 特征属性自动选择
    private func bestWriteType(
        for characteristic: CBCharacteristic,
        preferred: CBCharacteristicWriteType?
    ) -> CBCharacteristicWriteType? {
        // 如果偏好 .withoutResponse 且特征支持
        if preferred == .withoutResponse,
           characteristic.properties.contains(.writeWithoutResponse) {
            return .withoutResponse
        }

        // 如果偏好 .withResponse 且特征支持
        if preferred == .withResponse,
           characteristic.properties.contains(.write) {
            return .withResponse
        }

        // 没有偏好时自动选择：优先 .withoutResponse（更快）
        if characteristic.properties.contains(.writeWithoutResponse) {
            return .withoutResponse
        }

        // 回退到 .withResponse
        if characteristic.properties.contains(.write) {
            return .withResponse
        }

        return nil
    }

    // MARK: - 内部：特征发现与就绪

    /// 特征发现后，匹配角色并设置通知
    private func markReadyIfPossible(_ characteristic: CBCharacteristic, service: CBService) {
        // 方式一：根据 profile 配置匹配角色
        if let role = configuration.profile.role(for: characteristic, service: service) {
            characteristicsByRole[role] = characteristic
            characteristicRolesByUUID[characteristic.uuid] = role
        } else if configuration.profile.characteristics.isEmpty {
            // Demo fallback：没有 profile 时根据属性自动猜测角色。线上不要依赖这个逻辑。
            // 有 notify/indicate 属性 → 通知角色
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                characteristicsByRole[.notify] = characteristic
                characteristicRolesByUUID[characteristic.uuid] = .notify
            }
            // 有写入属性 → 命令/数据写入角色
            if characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write) {
                characteristicsByRole[.commandWrite] = characteristic
                characteristicsByRole[.dataWrite] = characteristic
                characteristicRolesByUUID[characteristic.uuid] = .dataWrite
            }
            // 有读取属性 → 读取角色
            if characteristic.properties.contains(.read) {
                characteristicsByRole[.read] = characteristic
                if characteristicRolesByUUID[characteristic.uuid] == nil {
                    characteristicRolesByUUID[characteristic.uuid] = .read
                }
            }
        }

        // 判断是否需要订阅通知
        let shouldNotifyByProfile = configuration.profile.characteristics.contains {
            $0.serviceUUID == service.uuid && $0.characteristicUUID == characteristic.uuid && $0.enableNotify
        }
        if shouldNotifyByProfile || characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
            connectedPeripheral?.setNotifyValue(true, for: characteristic)
        }

        // 至少有一个特征就绪时，标记整体就绪
        if !characteristicsByRole.isEmpty {
            markReady()
        }
    }

    /// 标记设备已就绪，可开始传输
    private func markReady() {
        guard let peripheral = connectedPeripheral else { return }
        metrics.readyAt = metrics.readyAt ?? Date()
        // 记录最大写入长度
        metrics.maximumWriteLength = peripheral.maximumWriteValueLength(for: .withoutResponse)
        connectionState = .ready(peripheral.identifier)
        notifyReadyRoles()
        notifyMetrics()
        // 如果有待恢复的断点续传，自动恢复
        resumePendingTransferIfNeeded()
    }

    /// 检查是否有待恢复的断点续传，有则自动恢复
    private func resumePendingTransferIfNeeded() {
        guard let ctx = pendingResume,
              characteristicsByRole[ctx.options.role] != nil,
              activeTransfer == nil else { return }

        // 从断点创建新的传输
        activeTransfer = ActiveTransfer(
            data: ctx.data,
            maxPayloadLength: ctx.maxPayloadLength,
            options: ctx.options,
            resumeOffset: ctx.ackedOffset
        )
        let resumedId = ctx.transferId
        let resumedOffset = ctx.ackedOffset
        pendingResume = nil
        flushActiveTransfer()
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didResumeTransfer: resumedId, fromOffset: resumedOffset) }
        }
    }

    // MARK: - 内部：工具方法

    /// 将数据按指定长度分块
    private func chunk(data: Data, maxLength: Int) -> [Data] {
        guard !data.isEmpty else { return [Data()] }
        return stride(from: 0, to: data.count, by: maxLength).map { offset in
            let end = min(offset + maxLength, data.count)
            return data.subdata(in: offset..<end)
        }
    }

    /// 从弱引用表中获取所有存活的 delegate
    private var delegates: [BluetoothManagerDelegate] {
        delegateTable.allObjects.compactMap { $0 as? BluetoothManagerDelegate }
    }

    // MARK: - 内部：通知方法

    /// 通知 delegate 设备列表更新
    private func notifyDiscoveredDevices() {
        // 按 RSSI 降序排列（信号强的在前）
        let devices = discoveredMap.values.sorted { $0.rssi > $1.rssi }
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didDiscover: devices) }
        }
    }

    /// 通知 delegate 连接状态变化
    private func notifyConnectionState(_ state: BluetoothConnectionState) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didChangeConnectionState: state) }
        }
    }

    /// 通知 delegate 特征角色就绪
    private func notifyReadyRoles() {
        let roles = Set(characteristicsByRole.keys)
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didUpdateReady: roles) }
        }
    }

    /// 通知 delegate 传输进度（节流：最少间隔 100ms，传输完成时立即通知）
    private func notifyProgress() {
        guard let transfer = activeTransfer else { return }
        let now = Date()
        let isComplete = transfer.isComplete
        // 节流：非完成状态下至少间隔 0.1 秒，避免高频回调卡顿主线程
        if !isComplete, let last = lastProgressNotifyTime, now.timeIntervalSince(last) < 0.1 {
            return
        }
        lastProgressNotifyTime = now
        let progress = BluetoothPacketProgress(
            sentBytes: transfer.ackedPayloadBytes,
            totalBytes: transfer.totalPayloadBytes
        )
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didUpdateTransfer: progress) }
        }
    }

    /// 通知 delegate 指标更新
    private func notifyMetrics() {
        let snapshot = metrics
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didUpdateMetrics: snapshot) }
        }
    }

    /// 通知 delegate 发生错误
    private func notifyFailure(_ error: Error) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didFail: error) }
        }
    }
}

// MARK: - CBCentralManagerDelegate

/// 中央管理器委托实现：扫描回调、连接回调、断开回调
extension BluetoothManager: CBCentralManagerDelegate {

    /// 蓝牙适配器状态变化
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didUpdateState: central.state) }
        }
    }

    /// 状态恢复：App 被系统杀掉后重新启动时恢复之前的连接
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        peripherals.forEach {
            $0.delegate = self
            connectedPeripheral = $0
            let device = BluetoothDevice(
                identifier: $0.identifier,
                name: $0.name ?? "Restored Device",
                rssi: 0,
                peripheral: $0
            )
            connectedDevice = device
            // 恢复后重新发现服务，以重建特征映射
            connectionState = .discovering($0.identifier)
            $0.discoverServices(configuration.profile.serviceUUIDs)
            DispatchQueue.main.async {
                self.delegates.forEach { $0.bluetoothManager(self, didConnect: device) }
            }
        }
    }

    /// 扫描发现新设备
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // 尝试从多个来源获取设备名称
        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "Unknown Device"
        let device = BluetoothDevice(
            identifier: peripheral.identifier,
            name: name,
            rssi: RSSI.intValue,
            peripheral: peripheral
        )
        // 更新信号强度
        metrics.lastRSSI = RSSI.intValue
        // 加入或更新设备字典（同一设备发现多次会更新 RSSI）
        discoveredMap[device.identifier] = device
        notifyDiscoveredDevices()
        notifyMetrics()
    }

    /// 连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 取消连接超时
        connectTimeoutWorkItem?.cancel()
        // 重置重连计数
        reconnectAttempts = 0
        metrics.reconnectAttempts = 0
        // 获取设备模型
        let device = discoveredMap[peripheral.identifier] ?? BluetoothDevice(
            identifier: peripheral.identifier,
            name: peripheral.name ?? "Bluetooth Device",
            rssi: 0,
            peripheral: peripheral
        )
        connectedDevice = device
        connectedPeripheral = peripheral
        peripheral.delegate = self
        // iOS 上 CoreBluetooth 会自动协商 MTU 到双方支持的最大值
        // maximumWriteValueLength(for:) 会返回协商后的最大写入长度
        // 进入服务发现阶段
        connectionState = .discovering(peripheral.identifier)
        peripheral.discoverServices(configuration.profile.serviceUUIDs)
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didConnect: device) }
        }
    }

    /// 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        notifyFailure(error ?? BluetoothError.peripheralNotFound)
        // 自动重连
        scheduleReconnect()
    }

    /// 连接断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let device = connectedDevice
        // 清理特征缓存
        characteristicsByRole.removeAll()
        characteristicRolesByUUID.removeAll()
        // 处理正在进行的传输
        if let transfer = activeTransfer {
            if transfer.options.supportsResume && error != nil {
                // 断点续传：保存上下文，等待重连后恢复
                pendingResume = (
                    data: transfer.sourceDataCopy,
                    maxPayloadLength: transfer.maxPayloadLength,
                    options: transfer.options,
                    ackedOffset: transfer.ackedOffset,
                    transferId: transfer.id
                )
                let pausedId = transfer.id
                let pausedOffset = transfer.ackedOffset
                cancelActiveTransfer()
                DispatchQueue.main.async {
                    self.delegates.forEach { $0.bluetoothManager(self, didPauseTransfer: pausedId, ackedOffset: pausedOffset) }
                }
            } else {
                // 不支持续传或主动断开 → 直接取消
                cancelActiveTransfer()
            }
        }
        connectionState = .disconnected(peripheral.identifier)
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didDisconnect: device, error: error) }
        }

        if error != nil && shouldAutoReconnect {
            // 异常断开且允许重连 → 触发自动重连（保留 peripheral 引用供重连使用）
            scheduleReconnect()
        } else {
            // 主动断开或不允许重连 → 清空引用，释放内存
            connectedPeripheral = nil
            connectedDevice = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

/// 外设委托实现：服务发现、特征发现、数据收发
extension BluetoothManager: CBPeripheralDelegate {

    /// 服务发现完成
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            notifyFailure(error)
            // 服务发现失败，标记失败并断开，让用户可以手动重连
            connectionState = .failed(error.localizedDescription)
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        // 对每个发现的服务，继续发现其特征
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(configuration.profile.characteristicUUIDs(for: service.uuid), for: service)
        }
    }

    /// 特征发现完成
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            notifyFailure(error)
            connectionState = .failed(error.localizedDescription)
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        // 逐个匹配特征角色并设置通知
        service.characteristics?.forEach { characteristic in
            markReadyIfPossible(characteristic, service: service)
        }
    }

    /// 收到外设发来的数据（notify/indicate 或 read 的回调）
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            notifyFailure(error)
            return
        }

        guard let data = characteristic.value else { return }
        // 更新接收字节数
        metrics.receivedBytes += data.count
        // 根据特征 UUID 反查角色
        let role = characteristicRolesByUUID[characteristic.uuid]

        // 尝试解码为应用层帧
        if let frame = BluetoothProtocolCodec.decode(data) {
            if handleApplicationFrame(frame) {
                // 是 ACK 帧且已处理
                notifyMetrics()
                return
            }
            // 是应用层帧但非 ACK（如 .data / .complete / .resumeRequest）
            // 传递纯净 payload，不包含帧头
            DispatchQueue.main.async {
                self.delegates.forEach { $0.bluetoothManager(self, didReceive: frame.payload, role: role) }
            }
            notifyMetrics()
            return
        }

        // 非应用层帧（裸数据），直接传递原始字节
        DispatchQueue.main.async {
            self.delegates.forEach { $0.bluetoothManager(self, didReceive: data, role: role) }
        }
        notifyMetrics()
    }

    /// 写入完成回调（仅 .withResponse 模式触发）
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            notifyFailure(error)
            // 写入失败，取消当前传输，避免卡在等 ACK 超时
            cancelActiveTransfer()
            return
        }
        // 释放一个写入响应槽位
        activeTransfer?.releaseWriteResponseSlot()
        // 继续刷新传输队列
        flushActiveTransfer()
    }

    /// 外设可以再次接受 .withoutResponse 写入
    /// 当 canSendWriteWithoutResponse 从 false 变为 true 时触发
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        flushActiveTransfer()
    }
}

// MARK: - ActiveTransfer（传输上下文）

/// 一次传输的完整上下文，管理数据包队列、ACK 状态、重试和超时。
/// 采用懒加载设计：只保存原始 Data，按需生成帧，避免大文件一次性加载全部帧到内存。
/// 生命周期：创建 → flushActiveTransfer 循环写入 → 全部 ACK → complete
private final class ActiveTransfer {

    /// 单个数据包
    struct Packet {
        /// 包序号（用于 ACK 匹配）
        let sequence: UInt32
        /// 编码后的帧数据（含头部或裸数据）
        let data: Data
        /// 原始 payload 大小（不含头部，用于进度统计）
        let payloadSize: Int
    }

    /// 本次传输的唯一 ID
    let id = UUID()
    /// 传输配置
    let options: BluetoothTransferOptions
    /// 总 payload 字节数（用于进度计算）
    let totalPayloadBytes: Int

    // MARK: 懒加载数据源

    /// 原始数据（仅保存引用，不预创建全部帧）
    private let sourceData: Data
    /// 每帧 payload 最大长度
    let maxPayloadLength: Int
    /// 是否使用应用层帧（sendRaw = false, sendReliableData = true）
    private let useApplicationFrame: Bool
    /// 总帧数
    private let totalFrameCount: Int

    // MARK: 传输状态

    /// 下一个待发送包的索引
    private var nextIndex: Int
    /// 待重试的数据包队列
    private var retryQueue: [Packet] = []
    /// 已发送但未确认的数据包（key 为序号）
    private var inFlight: [UInt32: Packet] = [:]
    /// 各包已重试的次数
    private var retryCounts: [UInt32: Int] = [:]
    /// 已确认的数据包序号集合（用于去重，防止重复 ACK）
    private var ackedSequences: Set<UInt32> = []
    /// 各包的超时定时器
    private var timeoutWorkItems: [UInt32: DispatchWorkItem] = [:]
    /// .withResponse 模式下正在等待响应的槽位数
    private var responseSlots = 0
    /// 已确认的字节数（累加，避免遍历全部包）
    private var ackedBytes: Int

    // MARK: 初始化

    /// 创建新传输
    init(data: Data, maxPayloadLength: Int, options: BluetoothTransferOptions) {
        self.options = options
        self.sourceData = data
        self.maxPayloadLength = max(1, maxPayloadLength)
        self.useApplicationFrame = options.useApplicationFrame
        self.totalPayloadBytes = data.count
        self.totalFrameCount = data.isEmpty ? 1 : (data.count + max(1, maxPayloadLength) - 1) / max(1, maxPayloadLength)
        self.nextIndex = 0
        self.ackedBytes = 0
    }

    /// 从断点恢复传输
    init(data: Data, maxPayloadLength: Int, options: BluetoothTransferOptions, resumeOffset: Int) {
        self.options = options
        self.sourceData = data
        self.maxPayloadLength = max(1, maxPayloadLength)
        self.useApplicationFrame = options.useApplicationFrame
        self.totalPayloadBytes = data.count
        let safePayload = max(1, maxPayloadLength)
        self.totalFrameCount = data.isEmpty ? 1 : (data.count + safePayload - 1) / safePayload
        self.nextIndex = resumeOffset / safePayload
        self.ackedBytes = resumeOffset
    }

    // MARK: 懒加载生成帧

    /// 按索引生成单个数据包（按需创建，不预存全部）
    private func makePacket(at index: Int) -> Packet {
        let payloadStart = index * maxPayloadLength
        let payloadEnd = min(payloadStart + maxPayloadLength, sourceData.count)
        let payload = sourceData.subdata(in: payloadStart..<payloadEnd)

        let encodedData: Data
        if useApplicationFrame {
            // 应用层帧：加帧头 + CRC32
            let frame = BluetoothProtocolFrame(
                type: .data,
                sequence: UInt32(index),
                offset: UInt32(payloadStart),
                totalLength: UInt32(sourceData.count),
                payload: payload
            )
            encodedData = BluetoothProtocolCodec.encode(frame)
        } else {
            // 裸数据：直接使用 payload
            encodedData = payload
        }

        return Packet(sequence: UInt32(index), data: encodedData, payloadSize: payload.count)
    }

    // MARK: 状态查询

    /// 已确认的 payload 字节数
    var ackedPayloadBytes: Int { ackedBytes }

    /// 已确认的字节偏移量（用于断点续传）
    var ackedOffset: Int { ackedBytes }

    /// 原始数据的拷贝（用于断点续传保存上下文）
    var sourceDataCopy: Data { sourceData }

    /// 所有包是否都已确认
    var isComplete: Bool { ackedBytes >= totalPayloadBytes }

    /// 是否可以发送下一个包
    /// 条件：有包待发 + 未超过 ACK 窗口 + 未超过响应窗口
    var canSendNext: Bool {
        guard !retryQueue.isEmpty || nextIndex < totalFrameCount else { return false }
        // applicationAck 模式：在途包数不能超过窗口
        if options.reliability == .applicationAck, inFlight.count >= options.ackWindow {
            return false
        }
        // .withResponse 模式：等待响应的包数不能超过窗口
        if options.writeType == .withResponse, responseSlots >= options.ackWindow {
            return false
        }
        return true
    }

    // MARK: 包操作

    /// 取下一个待发送的包（优先重试队列，否则懒加载生成新包）
    func nextPacket() -> Packet? {
        // 优先发送重试队列中的包
        if !retryQueue.isEmpty {
            let packet = retryQueue.removeFirst()
            inFlight[packet.sequence] = packet
            if options.writeType == .withResponse {
                responseSlots += 1
            }
            return packet
        }

        // 懒加载生成新包
        guard nextIndex < totalFrameCount else { return nil }
        let packet = makePacket(at: nextIndex)
        nextIndex += 1
        inFlight[packet.sequence] = packet
        if options.writeType == .withResponse {
            responseSlots += 1
        }
        return packet
    }

    /// 标记某个包为已确认
    func markAcked(sequence: UInt32) {
        guard !ackedSequences.contains(sequence) else { return } // 去重
        ackedSequences.insert(sequence)

        // 累加已确认字节数
        let index = Int(sequence)
        let payloadStart = index * maxPayloadLength
        let payloadEnd = min(payloadStart + maxPayloadLength, sourceData.count)
        ackedBytes += payloadEnd - payloadStart

        inFlight.removeValue(forKey: sequence)
        retryQueue.removeAll { $0.sequence == sequence }
        timeoutWorkItems[sequence]?.cancel()
        timeoutWorkItems.removeValue(forKey: sequence)
    }

    /// 重试某个包
    /// - Returns: true 表示可以重试，false 表示已超过最大重试次数
    func retry(sequence: UInt32) -> Bool {
        guard let packet = inFlight[sequence] else { return true }
        let count = retryCounts[sequence, default: 0] + 1
        retryCounts[sequence] = count
        // 超过最大重试次数，返回 false
        guard count <= options.maxRetries else { return false }
        // 从在途列表移除，加入重试队列
        inFlight.removeValue(forKey: sequence)
        timeoutWorkItems[sequence]?.cancel()
        timeoutWorkItems.removeValue(forKey: sequence)
        retryQueue.insert(packet, at: 0)
        return true
    }

    /// 注册某个包的超时定时器
    func registerTimeout(_ workItem: DispatchWorkItem, sequence: UInt32) {
        timeoutWorkItems[sequence]?.cancel()
        timeoutWorkItems[sequence] = workItem
    }

    /// 释放一个 .withResponse 的响应槽位
    func releaseWriteResponseSlot() {
        responseSlots = max(0, responseSlots - 1)
    }

    /// 取消所有超时定时器（传输取消时调用）
    func cancelTimeouts() {
        timeoutWorkItems.values.forEach { $0.cancel() }
        timeoutWorkItems.removeAll()
    }
}
