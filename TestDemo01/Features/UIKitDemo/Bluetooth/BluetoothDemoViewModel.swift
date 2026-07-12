//
//  BluetoothDemoViewModel.swift
//  TestDemo01
//
//  Created by Codex on 2026/7/11.
//

/// 蓝牙 Demo 的 ViewModel，作为 UI 控制器与 BluetoothManager 之间的中间层。
/// 职责：
/// 1. 持有 BluetoothManager 单例并注册为 delegate
/// 2. 将蓝牙回调转换为 @Published 属性供 UI 绑定
/// 3. 暴露简洁的业务方法（扫描、连接、发送命令、发送大数据、读取特征值）
/// 4. 维护日志队列，方便用户观察运行时行为

import Combine
import CoreBluetooth
import Foundation

final class BluetoothDemoViewModel: NSObject, ObservableObject {

    // MARK: - 常量

    /// 日志时间格式化器（复用，避免每次 addLog 都新建）
    private static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - UI 绑定属性

    /// 蓝牙适配器状态文本（如"蓝牙可用"、"未授权"等）
    @Published private(set) var stateText = "蓝牙初始化中"
    /// 扫描发现的设备列表
    @Published private(set) var devices: [BluetoothDevice] = []
    /// 当前已连接设备名称
    @Published private(set) var connectedDeviceName = "未连接"
    /// 特征就绪状态文本（如"特征角色就绪：commandWrite, notify"）
    @Published private(set) var readyText = "等待可写特征"
    /// 传输进度文本（如"45% (29491/65536 bytes)"）
    @Published private(set) var progressText = "0%"
    /// 运行时日志列表，最新日志在数组头部
    @Published private(set) var logs: [String] = []
    /// 是否正在扫描
    @Published private(set) var isScanning = false
    /// 是否已连接（含连接中/发现中/就绪）
    @Published private(set) var isConnected = false
    /// 特征是否就绪，可以收发数据
    @Published private(set) var isReady = false

    // MARK: - 依赖

    /// 蓝牙管理器，默认使用单例
    private let bluetoothManager: BluetoothManager
    /// 演示用的大数据 payload 大小：64KB
    private let samplePayloadSize = 64 * 1024

    // MARK: - 初始化

    /// - Parameter bluetoothManager: 蓝牙管理器，默认使用单例（测试时可注入 mock）
    init(bluetoothManager: BluetoothManager = .shared) {
        self.bluetoothManager = bluetoothManager
        super.init()
        // 注册为 delegate，接收蓝牙事件回调
        bluetoothManager.addDelegate(self)
        // 配置传输参数：通用 Demo 模式，扫描 12 秒超时，连接 8 秒超时，最多重连 5 次
        bluetoothManager.update(configuration: BluetoothTransferConfiguration(
            profile: .genericDemo,
            scanTimeout: 12,
            connectTimeout: 8,
            reconnectMaxAttempts: 5,
            reconnectBaseDelay: 1
        ))
    }

    deinit {
        // 移除 delegate，避免野指针回调
        bluetoothManager.removeDelegate(self)
    }

    // MARK: - 业务方法

    /// 开始扫描附近 BLE 设备
    func startScan() {
        addLog("开始扫描：使用 serviceUUID 过滤可减少无关广播，真实业务建议传目标服务 UUID。")
        bluetoothManager.startScan()
    }

    /// 停止扫描
    func stopScan() {
        bluetoothManager.stopScan()
        addLog("已停止扫描，避免扫描和连接/传输抢占蓝牙资源。")
    }

    /// 连接指定索引的设备
    /// - Parameter index: devices 数组中的索引
    func connectDevice(at index: Int) {
        guard devices.indices.contains(index) else { return }
        let device = devices[index]
        addLog("连接 \(device.name)，连接成功后只发现必要服务和特征。")
        bluetoothManager.connect(device)
    }

    /// 主动断开当前连接（不触发自动重连）
    func disconnect() {
        bluetoothManager.disconnect()
        addLog("主动断开：主动断开不触发自动重连。")
    }

    /// 发送一条简短命令（使用 fireAndForget 模式，不等待 ACK）
    func sendSmallCommand() {
        // 构造一条带时间戳的 PING 命令
        let command = Data("PING:\(Date().timeIntervalSince1970)".utf8)
        // 走原始写入接口，不加应用层包头
        bluetoothManager.sendRaw(command, role: .commandWrite)
        addLog("发送小命令：关键命令可用 ACK + 超时重试保证可靠性。")
    }

    /// 发送 64KB 的模拟大数据（使用可靠传输模式，含包头+CRC+ACK+重试）
    func sendLargePayload() {
        // 生成 64KB 的测试数据（0~254 循环填充）
        let payload = Data((0..<samplePayloadSize).map { UInt8($0 % 255) })
        // 使用可靠传输：应用层帧 + ACK 窗口 6 + 最多重试 3 次 + 超时 1.5 秒
        bluetoothManager.sendReliableData(payload, options: BluetoothTransferOptions(
            role: .dataWrite,
            reliability: .applicationAck,
            ackWindow: 6,
            maxRetries: 3,
            ackTimeout: 1.5,
            useApplicationFrame: true
        ))
        addLog("发送 64KB 可靠数据：App 层包头 + CRC + ACK 窗口 + 超时重试。")
    }

    /// 读取指定角色的特征值（结果通过 didReceive 回调返回）
    /// - Parameter role: 要读取的特征角色，默认 .read
    func readValue(role: BluetoothCharacteristicRole = .read) {
        bluetoothManager.readValue(role: role)
        addLog("读取特征值：角色 \(role.rawValue)。")
    }

    // MARK: - 内部方法

    /// 添加一条带时间戳的日志，新日志插入头部，最多保留 80 条
    private func addLog(_ message: String) {
        let text = "[\(Self.logDateFormatter.string(from: Date()))] \(message)"
        logs.insert(text, at: 0)
        // 超过上限时移除最旧的日志
        if logs.count > 80 {
            logs.removeLast()
        }
    }

    /// 将 CBManagerState 转为中文描述
    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:      return "未知"
        case .resetting:    return "重置中"
        case .unsupported:  return "设备不支持蓝牙"
        case .unauthorized: return "未授权"
        case .poweredOff:   return "蓝牙关闭"
        case .poweredOn:    return "蓝牙可用"
        @unknown default:   return "未知状态"
        }
    }
}

// MARK: - BluetoothManagerDelegate

/// 蓝牙事件回调实现，将底层事件转换为 @Published 属性和日志。
extension BluetoothDemoViewModel: BluetoothManagerDelegate {

    /// 蓝牙状态变化（如开关蓝牙、授权变化）
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: CBManagerState) {
        stateText = stateDescription(state)
        addLog("蓝牙状态：\(stateText)")
    }

    /// 发现新设备或设备信息更新
    func bluetoothManager(_ manager: BluetoothManager, didDiscover devices: [BluetoothDevice]) {
        self.devices = devices
        addLog("发现设备数量：\(devices.count)")
    }

    /// 连接状态变化（如 connecting → ready → disconnected）
    func bluetoothManager(_ manager: BluetoothManager, didChangeConnectionState state: BluetoothConnectionState) {
        // 根据状态机更新 UI 绑定标志
        switch state {
        case .scanning:
            isScanning = true
        case .idle:
            isScanning = false
        case .connecting, .discovering, .reconnecting:
            isScanning = false
            isConnected = true
            isReady = false
        case .ready:
            isScanning = false
            isConnected = true
            isReady = true
        case .disconnecting, .disconnected, .failed:
            isScanning = false
            isConnected = false
            isReady = false
        }
        addLog("连接状态：\(state)")
    }

    /// 连接成功，开始发现服务和特征
    func bluetoothManager(_ manager: BluetoothManager, didConnect device: BluetoothDevice) {
        connectedDeviceName = device.name
        readyText = "发现服务/特征中"
        addLog("已连接：\(device.name)，异常断开会按指数退避+随机抖动重连。")
    }

    /// 连接断开（主动或异常）
    func bluetoothManager(_ manager: BluetoothManager, didDisconnect device: BluetoothDevice?, error: Error?) {
        connectedDeviceName = "未连接"
        readyText = "等待可写特征"
        isReady = false
        isConnected = false
        let reason = error?.localizedDescription ?? "主动断开"
        addLog("连接断开：\(device?.name ?? "-")，原因：\(reason)")
    }

    /// 特征角色就绪，可以开始收发数据
    func bluetoothManager(_ manager: BluetoothManager, didUpdateReady roles: Set<BluetoothCharacteristicRole>) {
        let roleText = roles.map(\.rawValue).sorted().joined(separator: ", ")
        readyText = "特征角色就绪：\(roleText)"
        isReady = !roles.isEmpty
        addLog("特征角色就绪：\(roleText)，最大包长由 maximumWriteValueLength 动态决定。")
    }

    /// 收到外设发来的数据
    func bluetoothManager(_ manager: BluetoothManager, didReceive data: Data, role: BluetoothCharacteristicRole?) {
        addLog("收到 \(data.count) bytes，角色：\(role?.rawValue ?? "-")。")
    }

    /// 传输进度更新
    func bluetoothManager(_ manager: BluetoothManager, didUpdateTransfer progress: BluetoothPacketProgress) {
        progressText = "\(Int(progress.ratio * 100))% (\(progress.sentBytes)/\(progress.totalBytes) bytes)"
    }

    /// 整个传输完成
    func bluetoothManager(_ manager: BluetoothManager, didCompleteTransfer id: UUID) {
        addLog("传输完成：\(id.uuidString)")
    }

    /// 运行时指标更新（连接耗时、收发字节数等）
    func bluetoothManager(_ manager: BluetoothManager, didUpdateMetrics metrics: BluetoothMetricSnapshot) {
        if let cost = metrics.connectionCost {
            addLog("指标：连接耗时 \(String(format: "%.2f", cost))s，TX \(metrics.transmittedBytes) bytes，RX \(metrics.receivedBytes) bytes。")
        }
    }

    /// 发生错误
    func bluetoothManager(_ manager: BluetoothManager, didFail error: Error) {
        addLog("错误：\(error.localizedDescription)")
    }
}
