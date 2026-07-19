//
//  MQTTManager.swift
//  TestDemo01
//
//  Created by Qoder on 2026/7/19.
//

/// MQTT 核心管理器，对第三方库 CocoaMQTT（2.1.6）的二次封装，提供生产级的消息通信流程：
///
/// **主要职责：**
/// 1. 连接管理 —— connect / disconnect，连接超时保护，异常断开自动重连（指数退避 + 随机抖动）
/// 2. 消息收发 —— publish / subscribe / unsubscribe，通过自定义 MQTTQoS 枚举屏蔽第三方类型
/// 3. 状态管理 —— 维护连接状态机（NSLock 线程安全），通过 weak delegate 模式通知外部
/// 4. 订阅恢复 —— 重连成功后自动恢复断线前的全部订阅
/// 5. 离线缓存 —— 未连接时 QoS1/2 消息可入离线缓存，重连成功后自动补发（可开关、限容量）
/// 6. 指标统计 —— 记录连接耗时、收发消息数、收发字节数、重连次数等
///
/// **线程模型：**
/// CocoaMQTT 的 socket 与大部分 delegate 回调通过 `delegateQueue` 绑定到专用串行队列 `queue`；
/// 但发布确认等回调来自库内部 deliver 队列，因此所有回调入口统一经 DispatchSpecificKey
/// 检测后调度到 `queue`，对外通知再统一切回主线程，使用方无需关心线程切换。
///
/// **关键设计决策（与蓝牙封装的差异点）：**
/// - 外部不直接依赖 CocoaMQTT 类型（QoS / 消息 / ACK 均使用自定义模型），便于后续替换底层库
/// - 关闭库自带的 autoReconnect，自管理 equal-jitter 指数退避重连，避免多设备同步重连的惊群效应
/// - CONNACK 被拒绝（认证失败等）属于应用层拒绝，**不进入自动重连**——这是与蓝牙连接模型的本质差异
/// - QoS0 实时消息断线即弃；QoS1/2 未 ACK 消息由库内 deliver 窗口自动重发，本层只缓存"未连接时的发布请求"
/// - 主动断开时若 socket 尚未完全建立，库不会回调断开事件，本层内置 3s 兜底定时器防止状态机卡死
/// - delegate 使用 NSHashTable.weakObjects 弱引用，避免循环引用
/// - 连接超时、重连延迟、断开兜底均通过 DispatchWorkItem 管理，可取消

import CocoaMQTT
import Foundation

// MARK: - 服务质量

/// MQTT 服务质量等级（与 CocoaMQTTQoS 解耦，外部不感知第三方类型）
enum MQTTQoS: Int, CaseIterable {
    /// 最多投递一次，可能丢消息，适合高频实时数据
    case atMostOnce = 0
    /// 至少投递一次，保证到达但可能重复，适合常规业务消息
    case atLeastOnce = 1
    /// 恰好投递一次，开销最大，适合支付/指令等强一致场景
    case exactlyOnce = 2

    /// 转为 CocoaMQTT 的 QoS 类型
    var cocoaQoS: CocoaMQTTQoS {
        switch self {
        case .atMostOnce:  return .qos0
        case .atLeastOnce: return .qos1
        case .exactlyOnce: return .qos2
        }
    }

    /// 从 CocoaMQTT 的 QoS 类型转换
    init(cocoaQoS: CocoaMQTTQoS) {
        switch cocoaQoS {
        case .qos0: self = .atMostOnce
        case .qos1: self = .atLeastOnce
        case .qos2: self = .exactlyOnce
        // FAILURE 仅用于 SUBACK 响应，不会出现在消息里，防御性映射
        case .FAILURE: self = .atMostOnce
        @unknown default: self = .atMostOnce
        }
    }
}

// MARK: - 数据模型

/// MQTT 消息模型（收发统一使用，屏蔽 CocoaMQTTMessage）
struct MQTTMessage {
    /// 主题（支持通配符 +/#，仅订阅时）
    let topic: String
    /// 消息体二进制数据
    let payload: Data
    /// 服务质量等级
    let qos: MQTTQoS
    /// 是否为保留消息（broker 会为该 topic 保留最后一条 retained 消息）
    let retained: Bool
    /// 消息 ID（QoS0 恒为 0，仅发布方向有意义）
    let messageID: UInt16
    /// 消息产生/到达时间戳
    let timestamp: Date

    /// payload 的 UTF-8 字符串表示
    var string: String? {
        String(data: payload, encoding: .utf8)
    }

    /// 由 CocoaMQTT 消息转换（接收方向）
    init(cocoaMessage: CocoaMQTTMessage, messageID: UInt16) {
        self.topic = cocoaMessage.topic
        self.payload = Data(cocoaMessage.payload)
        self.qos = MQTTQoS(cocoaQoS: cocoaMessage.qos)
        self.retained = cocoaMessage.retained
        self.messageID = messageID
        self.timestamp = Date()
    }

    /// 手动构造（发布方向）
    init(topic: String, payload: Data, qos: MQTTQoS = .atLeastOnce, retained: Bool = false, messageID: UInt16 = 0) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retained = retained
        self.messageID = messageID
        self.timestamp = Date()
    }

    /// 转为 CocoaMQTT 消息（发布方向，保留二进制 payload）
    var cocoaMessage: CocoaMQTTMessage {
        CocoaMQTTMessage(topic: topic, payload: [UInt8](payload), qos: qos.cocoaQoS, retained: retained)
    }
}

// MARK: - 连接配置

/// MQTT 连接全局配置
struct MQTTConfiguration {
    /// Broker 地址（默认 EMQX 公共测试 Broker，仅用于演示）
    var host: String = "broker.emqx.io"
    /// Broker 端口（1883 明文 / 8883 TLS）
    var port: UInt16 = 1883
    /// 客户端唯一标识符，同一 Broker 下不可重复，重复会互相挤下线
    var clientID: String = "ios-\(UUID().uuidString.prefix(8).lowercased())"
    /// 用户名（可选）
    var username: String?
    /// 密码（可选）
    var password: String?
    /// 心跳间隔（秒），客户端与 Broker 协商的保活周期
    var keepAlive: UInt16 = 60
    /// 是否为干净会话：true 断线后 Broker 不保留订阅与离线消息；false 则保留
    var cleanSession: Bool = true
    /// 是否启用 TLS（端口通常需配套改为 8883）
    var enableTLS: Bool = false
    /// 连接超时时间（秒），超时后放弃本次连接并进入重连流程
    var connectTimeout: TimeInterval = 10
    /// 最大重连次数（异常断开后），超过后进入 disconnected 状态并上报错误
    var reconnectMaxAttempts: Int = 5
    /// 重连基础延迟（秒），实际延迟按指数退避：baseDelay × 2^(attempt-1)，再加随机抖动
    var reconnectBaseDelay: TimeInterval = 1
    /// 遗嘱消息：客户端异常断开时由 Broker 代为发布，常用于上报离线状态
    var willMessage: MQTTMessage?
    /// 是否信任自签名 CA 证书（仅 enableTLS = true 时生效）
    /// - Warning: 生产环境慎用，信任任意证书会失去中间人攻击防护，仅建议内网自签名场景
    var allowUntrustCA: Bool = false
    /// 未确认的 QoS1/2 消息在途窗口大小（库默认值 10）
    var inflightWindowSize: UInt = 10
    /// QoS1/2 消息发送队列上限（库默认值 1000，满时新发布消息被丢弃）
    var messageQueueSize: UInt = 1000
    /// 是否缓存离线消息：未连接时 QoS1/2 的发布请求入离线缓存，重连成功后自动补发
    var cacheOfflineMessages: Bool = true
    /// 离线消息缓存上限，超出后丢弃最旧的消息
    var offlineMessageLimit: Int = 100
}

// MARK: - 连接状态机

/// MQTT 连接状态机
enum MQTTConnectionState: Equatable {
    /// 空闲未连接
    case disconnected
    /// 正在建立连接
    case connecting
    /// 已连接，可正常收发
    case connected
    /// 等待重连（附带当前是第几次重连尝试）
    case reconnecting(attempt: Int)
    /// 正在主动断开
    case disconnecting

    /// 是否处于可用（已连接）状态
    var isConnected: Bool {
        self == .connected
    }
}

// MARK: - 运行时指标

/// MQTT 连接与消息收发的运行时指标快照
struct MQTTMetricSnapshot {
    /// 连接开始的时间戳
    var connectStartedAt: Date?
    /// 连接成功（收到 CONNACK）的时间戳
    var connectedAt: Date?
    /// 已尝试重连的次数
    var reconnectAttempts: Int = 0
    /// 已发布消息条数
    var publishedCount: Int = 0
    /// 已接收消息条数
    var receivedCount: Int = 0
    /// 已发送的字节数（仅统计 payload）
    var transmittedBytes: Int = 0
    /// 已接收的字节数（仅统计 payload）
    var receivedBytes: Int = 0

    /// 从开始连接到连接成功的耗时（秒），用于评估连接性能
    var connectionCost: TimeInterval? {
        guard let connectStartedAt, let connectedAt else { return nil }
        return connectedAt.timeIntervalSince(connectStartedAt)
    }
}

// MARK: - Delegate 协议

/// MQTT 管理器的委托协议，通过 weak 方式持有，支持多对象同时监听。
/// 所有方法都有默认空实现，使用方只需实现关心的回调；所有回调均在主线程触发。
protocol MQTTManagerDelegate: AnyObject {
    /// 连接状态机变化（如 connecting → connected → reconnecting）
    func mqttManager(_ manager: MQTTManager, didChangeConnectionState state: MQTTConnectionState)
    /// 连接成功（收到 Broker CONNACK）
    func mqttManager(_ manager: MQTTManager, didConnect host: String, port: UInt16)
    /// 连接断开（主动或异常，异常时附带错误）
    func mqttManager(_ manager: MQTTManager, didDisconnect error: Error?)
    /// 收到订阅消息
    func mqttManager(_ manager: MQTTManager, didReceive message: MQTTMessage)
    /// 消息发布成功（QoS0 发出即回调，QoS1/2 收到 Broker ACK 后回调）
    func mqttManager(_ manager: MQTTManager, didPublish messageID: UInt16, topic: String)
    /// 订阅结果（成功 topic 与其被授予的 QoS，失败 topic 列表）
    func mqttManager(_ manager: MQTTManager, didSubscribe success: [String: MQTTQoS], failed: [String])
    /// 取消订阅成功
    func mqttManager(_ manager: MQTTManager, didUnsubscribe topics: [String])
    /// 运行时指标更新
    func mqttManager(_ manager: MQTTManager, didUpdateMetrics metrics: MQTTMetricSnapshot)
    /// 发生错误
    func mqttManager(_ manager: MQTTManager, didFail error: Error)
}

/// 协议方法的默认空实现，让使用方可以只实现关心的回调
extension MQTTManagerDelegate {
    func mqttManager(_ manager: MQTTManager, didChangeConnectionState state: MQTTConnectionState) {}
    func mqttManager(_ manager: MQTTManager, didConnect host: String, port: UInt16) {}
    func mqttManager(_ manager: MQTTManager, didDisconnect error: Error?) {}
    func mqttManager(_ manager: MQTTManager, didReceive message: MQTTMessage) {}
    func mqttManager(_ manager: MQTTManager, didPublish messageID: UInt16, topic: String) {}
    func mqttManager(_ manager: MQTTManager, didSubscribe success: [String: MQTTQoS], failed: [String]) {}
    func mqttManager(_ manager: MQTTManager, didUnsubscribe topics: [String]) {}
    func mqttManager(_ manager: MQTTManager, didUpdateMetrics metrics: MQTTMetricSnapshot) {}
    func mqttManager(_ manager: MQTTManager, didFail error: Error) {}
}

// MARK: - 错误类型

/// MQTT 操作可能产生的错误
enum MQTTError: LocalizedError {
    /// 配置非法（如 host 为空、端口为 0）
    case invalidConfiguration(String)
    /// 当前未连接，且离线缓存未开启或消息为 QoS0，无法执行发布
    case notConnected
    /// 已有连接或连接流程进行中
    case alreadyConnected
    /// 连接超时
    case connectTimeout
    /// Broker 拒绝连接（CONNACK 返回非 accept，附带原因描述），此类错误不触发自动重连
    case connectRejected(String)
    /// 重连次数已用尽
    case reconnectExhausted(attempts: Int)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason):
            return "MQTT configuration is invalid: \(reason)"
        case .notConnected:
            return "MQTT client is not connected."
        case .alreadyConnected:
            return "MQTT client is already connected or connecting."
        case .connectTimeout:
            return "MQTT connection timed out."
        case .connectRejected(let reason):
            return "MQTT connection rejected by broker: \(reason)"
        case .reconnectExhausted(let attempts):
            return "MQTT reconnect attempts exhausted: \(attempts)"
        }
    }
}

// MARK: - MQTTManager

/// MQTT 核心管理器（单例）
final class MQTTManager: NSObject {

    // MARK: 单例

    /// 全局单例
    static let shared = MQTTManager()

    // MARK: 内部状态

    /// MQTT 操作的专用串行队列，所有 CocoaMQTT 调用与状态变更都在此队列上
    private let queue = DispatchQueue(label: "com.testdemo.mqtt.manager")
    /// 队列标记 Key，用于检测当前是否已在 queue 上（防止 sync 死锁、保证回调线程安全）
    private let queueSpecificKey = DispatchSpecificKey<UInt8>()
    /// 队列标记值
    private let queueSpecificValue: UInt8 = 0x4D
    /// 弱引用 delegate 表，支持多个监听者，自动释放
    private let delegateTable = NSHashTable<AnyObject>.weakObjects()
    /// CocoaMQTT 客户端实例（每次 connect 按最新配置重建）
    private var client: CocoaMQTT?

    /// 当前连接配置
    private var configuration = MQTTConfiguration()
    /// 是否允许自动重连（主动断开时设为 false）
    private var shouldAutoReconnect = true
    /// 当前已尝试的重连次数
    private var reconnectAttempts = 0
    /// 延迟重连的 DispatchWorkItem
    private var pendingReconnectWorkItem: DispatchWorkItem?
    /// 连接超时的 DispatchWorkItem
    private var connectTimeoutWorkItem: DispatchWorkItem?
    /// 主动断开兜底定时器：socket 未完全建立时库不会回调断开事件，超时强制收尾
    private var disconnectFallbackWorkItem: DispatchWorkItem?
    /// CONNACK 被拒绝标记：拒绝属于应用层失败，随后的 socket 断开回调不得进入自动重连
    private var isConnectRejected = false
    /// 当前生效的订阅关系（topic → QoS），断线期间保留，重连成功后自动恢复
    private var activeSubscriptions: [String: MQTTQoS] = [:]
    /// 离线消息缓存（仅 QoS1/2），重连成功后自动补发
    private var offlineOutbox: [MQTTMessage] = []
    /// 运行时指标
    private var metrics = MQTTMetricSnapshot()

    /// 连接状态机线程安全锁
    private let stateLock = NSLock()
    /// 连接状态机（内部存储）
    private var _connectionState: MQTTConnectionState = .disconnected
    /// 连接状态机（线程安全读取），变化时自动通知 delegate
    private(set) var connectionState: MQTTConnectionState {
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

    /// 当前是否已连接
    var isConnected: Bool {
        connectionState.isConnected
    }

    /// 当前使用的 Broker 地址
    var currentHost: String {
        configuration.host
    }

    /// 当前生效的订阅 topic 列表
    var subscribedTopics: [String] {
        Array(activeSubscriptions.keys).sorted()
    }

    /// 离线缓存中待补发的消息条数
    var offlineOutboxCount: Int {
        onQueueSync { offlineOutbox.count }
    }

    // MARK: 初始化

    /// 私有初始化，保证单例
    private override init() {
        super.init()
        // 打上队列标记，供 onQueue / onQueueSync 检测当前线程
        queue.setSpecific(key: queueSpecificKey, value: queueSpecificValue)
    }

    // MARK: - 队列调度

    /// 在 queue 上异步执行任务；若当前已在 queue 上（含库内部回调）则直接同步执行
    private func onQueue(_ work: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: queueSpecificKey) == queueSpecificValue {
            work()
        } else {
            queue.async(execute: work)
        }
    }

    /// 在 queue 上同步执行任务并返回结果；若当前已在 queue 上则直接执行，避免 sync 死锁
    private func onQueueSync<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueSpecificKey) == queueSpecificValue {
            return work()
        }
        return queue.sync(execute: work)
    }

    // MARK: - Delegate 管理

    /// 添加监听者（弱引用，无需手动移除，但建议在 deinit 中移除）
    /// - Note: 在主线程调用时同步注册，避免错过即时事件
    func addDelegate(_ delegate: MQTTManagerDelegate) {
        if Thread.isMainThread {
            delegateTable.add(delegate)
        } else {
            DispatchQueue.main.async { self.delegateTable.add(delegate) }
        }
    }

    /// 移除监听者
    func removeDelegate(_ delegate: MQTTManagerDelegate) {
        if Thread.isMainThread {
            delegateTable.remove(delegate)
        } else {
            DispatchQueue.main.async { self.delegateTable.remove(delegate) }
        }
    }

    // MARK: - 配置

    /// 更新连接配置（线程安全）
    /// - Note: 已连接状态下调用不会断开当前连接，新配置在下次 connect 时生效
    func update(configuration: MQTTConfiguration) {
        onQueue {
            self.configuration = configuration
        }
    }

    // MARK: - 连接

    /// 按当前配置建立连接，开启自动重连
    func connect() {
        onQueue {
            // 已连接或连接中，避免重复发起
            guard self.connectionState == .disconnected else {
                self.notifyFailure(MQTTError.alreadyConnected)
                return
            }
            self.shouldAutoReconnect = true
            self.reconnectAttempts = 0
            self.connectInternal()
        }
    }

    /// 断开当前连接（不触发自动重连）
    /// - Note: 离线缓存不会清空，下次连接成功后仍会补发
    func disconnect() {
        onQueue {
            self.shouldAutoReconnect = false
            // 取消所有待处理的延迟操作
            self.pendingReconnectWorkItem?.cancel()
            self.pendingReconnectWorkItem = nil
            self.cancelConnectTimeout()
            guard let client = self.client else {
                self.connectionState = .disconnected
                return
            }
            self.connectionState = .disconnecting
            client.disconnect()
            // 兜底：socket 未完全建立时库不会回调断开事件，3 秒后强制收尾，防止状态机卡死
            self.scheduleDisconnectFallback()
        }
    }

    // MARK: - 发布

    /// 发布字符串消息
    /// - Parameters:
    ///   - text: 消息文本（UTF-8 编码）
    ///   - topic: 目标主题（不可含通配符）
    ///   - qos: 服务质量等级，默认 atLeastOnce
    ///   - retained: 是否保留消息，默认 false
    /// - Returns: 消息 ID。>= 0 为正常（QoS0 恒为 0）；-1 发布失败（未连接且未缓存）；-2 已入离线缓存待补发
    @discardableResult
    func publish(_ text: String, topic: String, qos: MQTTQoS = .atLeastOnce, retained: Bool = false) -> Int {
        publish(Data(text.utf8), topic: topic, qos: qos, retained: retained)
    }

    /// 发布二进制消息
    /// - Parameters:
    ///   - payload: 消息体数据（二进制原样发送，不做 UTF-8 转换）
    ///   - topic: 目标主题（不可含通配符）
    ///   - qos: 服务质量等级，默认 atLeastOnce
    ///   - retained: 是否保留消息，默认 false
    /// - Returns: 消息 ID。>= 0 为正常（QoS0 恒为 0）；-1 发布失败（未连接且未缓存）；-2 已入离线缓存待补发
    @discardableResult
    func publish(_ payload: Data, topic: String, qos: MQTTQoS = .atLeastOnce, retained: Bool = false) -> Int {
        onQueueSync {
            guard self.connectionState == .connected, let client = self.client else {
                // 未连接：QoS1/2 按配置进入离线缓存，重连成功后自动补发；QoS0 实时消息直接丢弃
                if self.configuration.cacheOfflineMessages, qos != .atMostOnce {
                    // 超出上限时丢弃最旧的消息
                    if self.offlineOutbox.count >= self.configuration.offlineMessageLimit {
                        self.offlineOutbox.removeFirst()
                    }
                    self.offlineOutbox.append(MQTTMessage(topic: topic, payload: payload, qos: qos, retained: retained))
                    return -2
                }
                self.notifyFailure(MQTTError.notConnected)
                return -1
            }
            let messageID = client.publish(MQTTMessage(topic: topic, payload: payload, qos: qos, retained: retained).cocoaMessage)
            // 统计发送指标
            self.metrics.publishedCount += 1
            self.metrics.transmittedBytes += payload.count
            self.notifyMetrics()
            return messageID
        }
    }

    // MARK: - 订阅

    /// 订阅主题（支持通配符 + 与 #）
    /// - Parameters:
    ///   - topic: 主题过滤串
    ///   - qos: 期望的服务质量等级，最终以 Broker 授予为准（见 didSubscribe 回调）
    /// - Note: 未连接时调用会记录订阅关系，重连成功后自动补订
    func subscribe(topic: String, qos: MQTTQoS = .atLeastOnce) {
        onQueue {
            // 先记录订阅关系，断线期间的订阅在重连成功后统一恢复
            self.activeSubscriptions[topic] = qos
            guard self.connectionState == .connected, let client = self.client else {
                return
            }
            client.subscribe(topic, qos: qos.cocoaQoS)
        }
    }

    /// 取消订阅主题
    /// - Parameter topic: 已订阅的主题过滤串
    func unsubscribe(topic: String) {
        onQueue {
            self.activeSubscriptions.removeValue(forKey: topic)
            guard self.connectionState == .connected, let client = self.client else {
                return
            }
            client.unsubscribe(topic)
        }
    }

    // MARK: - 心跳与指标

    /// 手动发送一次心跳 PING（库已按 keepAlive 自动保活，此方法仅供调试使用）
    func ping() {
        onQueue {
            self.client?.ping()
        }
    }

    /// 重置运行时指标（清零收发计数与重连次数）
    func resetMetrics() {
        onQueue {
            self.metrics = MQTTMetricSnapshot()
            self.notifyMetrics()
        }
    }

    // MARK: - 内部：连接流程

    /// 在 queue 上按当前配置重建客户端并发起连接
    /// - Note: 必须在 queue 上调用
    private func connectInternal() {
        // 校验基本配置
        guard !configuration.host.isEmpty, configuration.port > 0 else {
            notifyFailure(MQTTError.invalidConfiguration("host or port is empty"))
            connectionState = .disconnected
            return
        }

        // 防御性清理旧实例：置空 delegate，避免旧 socket 的断开回调干扰新状态机
        if let oldClient = client {
            oldClient.delegate = nil
            oldClient.disconnect()
            client = nil
        }
        isConnectRejected = false

        // 按最新配置重建客户端实例
        let client = CocoaMQTT(clientID: configuration.clientID,
                               host: configuration.host,
                               port: configuration.port)
        client.username = configuration.username
        client.password = configuration.password
        client.keepAlive = configuration.keepAlive
        client.cleanSession = configuration.cleanSession
        client.enableSSL = configuration.enableTLS
        client.allowUntrustCACertificate = configuration.allowUntrustCA
        client.inflightWindowSize = configuration.inflightWindowSize
        client.messageQueueSize = configuration.messageQueueSize
        // 关闭库自带的固定间隔重连，由本类自管理 equal-jitter 指数退避重连
        client.autoReconnect = false
        client.delegate = self
        // socket 与 delegate 回调统一切到专用串行队列
        client.delegateQueue = queue
        // 配置遗嘱消息（异常断开时由 Broker 代为发布，二进制 payload 原样传递）
        if let will = configuration.willMessage {
            client.willMessage = will.cocoaMessage
        }
        self.client = client

        // 记录连接开始时间，用于统计连接耗时
        metrics.connectStartedAt = Date()
        metrics.connectedAt = nil
        // 首轮连接推进到 connecting；重连尝试保持 reconnecting（携带 attempt 信息）
        if case .reconnecting = connectionState {
            // 保持 reconnecting 状态
        } else {
            connectionState = .connecting
        }
        // 发起连接，返回 false 表示 socket 立即失败（如 host 无法解析）
        if !client.connect() {
            notifyFailure(MQTTError.connectRejected("socket connect failed immediately"))
            handleUnexpectedDisconnect(error: nil)
            return
        }
        scheduleConnectTimeout()
    }

    /// 在 queue 上处理异常断开：尝试自动重连或宣告失败
    /// - Note: 必须在 queue 上调用
    private func handleUnexpectedDisconnect(error: Error?) {
        // 主动断开流程不触发重连，状态由 disconnect() 自身推进
        guard shouldAutoReconnect else {
            connectionState = .disconnected
            notifyDisconnected(error: error)
            return
        }

        guard reconnectAttempts < configuration.reconnectMaxAttempts else {
            // 重连次数用尽，宣告失败并回到空闲
            connectionState = .disconnected
            notifyFailure(MQTTError.reconnectExhausted(attempts: reconnectAttempts))
            notifyDisconnected(error: error)
            return
        }

        reconnectAttempts += 1
        metrics.reconnectAttempts = reconnectAttempts
        notifyMetrics()
        connectionState = .reconnecting(attempt: reconnectAttempts)

        // equal-jitter 指数退避：fullDelay = baseDelay × 2^(attempt-1)，
        // 最终延迟 = fullDelay / 2 + random(0, fullDelay / 2)，避免多设备同步重连的惊群效应
        let fullDelay = configuration.reconnectBaseDelay * pow(2, Double(reconnectAttempts - 1))
        let jitteredDelay = fullDelay / 2 + Double.random(in: 0..<(fullDelay / 2))
        let workItem = DispatchWorkItem { [weak self] in
            self?.connectInternal()
        }
        pendingReconnectWorkItem = workItem
        queue.asyncAfter(deadline: .now() + jitteredDelay, execute: workItem)
    }

    /// 在 queue 上恢复断线前的全部订阅
    /// - Note: 必须在 queue 上调用，且仅重连成功后调用（首轮连接由业务方自行订阅）
    private func restoreSubscriptionsIfNeeded() {
        guard !activeSubscriptions.isEmpty, let client = client else { return }
        for (topic, qos) in activeSubscriptions {
            client.subscribe(topic, qos: qos.cocoaQoS)
        }
    }

    /// 在 queue 上补发离线缓存的全部消息
    /// - Note: 必须在 queue 上调用，且仅连接成功后调用
    private func flushOfflineOutbox() {
        guard connectionState == .connected, let client = client, !offlineOutbox.isEmpty else { return }
        let pending = offlineOutbox
        offlineOutbox.removeAll()
        for message in pending {
            client.publish(message.cocoaMessage)
            metrics.publishedCount += 1
            metrics.transmittedBytes += message.payload.count
        }
        notifyMetrics()
    }

    // MARK: - 内部：超时与兜底

    /// 在 queue 上调度连接超时（首轮连接与重连尝试均受保护）
    /// - Note: 必须在 queue 上调用
    private func scheduleConnectTimeout() {
        connectTimeoutWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // 仅在等待 CONNACK 阶段判定超时
            switch self.connectionState {
            case .connecting, .reconnecting:
                break
            default:
                return
            }
            self.notifyFailure(MQTTError.connectTimeout)
            self.client?.disconnect()
            self.handleUnexpectedDisconnect(error: MQTTError.connectTimeout)
        }
        connectTimeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + configuration.connectTimeout, execute: workItem)
    }

    /// 在 queue 上取消连接超时
    /// - Note: 必须在 queue 上调用
    private func cancelConnectTimeout() {
        connectTimeoutWorkItem?.cancel()
        connectTimeoutWorkItem = nil
    }

    /// 在 queue 上调度主动断开兜底：socket 未完全建立时库不会回调断开事件，超时强制收尾
    /// - Note: 必须在 queue 上调用
    private func scheduleDisconnectFallback() {
        cancelDisconnectFallback()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, case .disconnecting = self.connectionState else { return }
            self.client = nil
            self.connectionState = .disconnected
            self.notifyDisconnected(error: nil)
        }
        disconnectFallbackWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    /// 在 queue 上取消主动断开兜底
    /// - Note: 必须在 queue 上调用
    private func cancelDisconnectFallback() {
        disconnectFallbackWorkItem?.cancel()
        disconnectFallbackWorkItem = nil
    }

    // MARK: - 内部：通知方法

    /// 当前全部 delegate（主线程读取）
    private var delegates: [MQTTManagerDelegate] {
        delegateTable.allObjects.compactMap { $0 as? MQTTManagerDelegate }
    }

    /// 通知 delegate 连接状态变化
    private func notifyConnectionState(_ state: MQTTConnectionState) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didChangeConnectionState: state) }
        }
    }

    /// 通知 delegate 连接成功
    private func notifyConnect() {
        let host = configuration.host
        let port = configuration.port
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didConnect: host, port: port) }
        }
    }

    /// 通知 delegate 连接断开
    private func notifyDisconnected(error: Error?) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didDisconnect: error) }
        }
    }

    /// 通知 delegate 收到订阅消息
    private func notifyMessage(_ message: MQTTMessage) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didReceive: message) }
        }
    }

    /// 通知 delegate 消息发布成功
    private func notifyPublish(messageID: UInt16, topic: String) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didPublish: messageID, topic: topic) }
        }
    }

    /// 通知 delegate 订阅结果
    private func notifySubscribe(success: [String: MQTTQoS], failed: [String]) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didSubscribe: success, failed: failed) }
        }
    }

    /// 通知 delegate 取消订阅成功
    private func notifyUnsubscribe(topics: [String]) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didUnsubscribe: topics) }
        }
    }

    /// 通知 delegate 运行时指标更新
    private func notifyMetrics() {
        let snapshot = metrics
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didUpdateMetrics: snapshot) }
        }
    }

    /// 通知 delegate 发生错误
    private func notifyFailure(_ error: Error) {
        DispatchQueue.main.async {
            self.delegates.forEach { $0.mqttManager(self, didFail: error) }
        }
    }
}

// MARK: - CocoaMQTTDelegate

/// CocoaMQTT 委托实现。
/// socket 相关回调在 delegateQueue（即本类 queue）上触发；发布确认等回调来自库内部
/// deliver 队列，因此所有入口统一经 onQueue 调度，保证状态访问的线程安全。
extension MQTTManager: CocoaMQTTDelegate {

    /// 收到 Broker 的 CONNACK（连接确认）
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        onQueue {
            self.cancelConnectTimeout()
            if ack == .accept {
                let wasReconnecting: Bool
                if case .reconnecting = self.connectionState {
                    wasReconnecting = true
                } else {
                    wasReconnecting = false
                }
                // 连接成功：记录耗时、清零重连计数
                self.metrics.connectedAt = Date()
                self.reconnectAttempts = 0
                self.connectionState = .connected
                self.notifyConnect()
                self.notifyMetrics()
                // 重连成功后自动恢复断线前的订阅、补发离线缓存
                if wasReconnecting {
                    self.restoreSubscriptionsIfNeeded()
                }
                self.flushOfflineOutbox()
            } else {
                // Broker 拒绝连接（认证失败等应用层拒绝）：置标记，随后的 socket 断开回调不进入重连
                self.isConnectRejected = true
                self.connectionState = .disconnected
                let error = MQTTError.connectRejected("\(ack)")
                self.notifyFailure(error)
                self.notifyDisconnected(error: error)
            }
        }
    }

    /// 收到订阅消息
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        onQueue {
            // 统计接收指标
            self.metrics.receivedCount += 1
            self.metrics.receivedBytes += message.payload.count
            self.notifyMetrics()
            self.notifyMessage(MQTTMessage(cocoaMessage: message, messageID: id))
        }
    }

    /// 消息已发出（QoS0 发出即回调，QoS1/2 在 PUB 流程发出后回调）
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        onQueue {
            self.notifyPublish(messageID: id, topic: message.topic)
        }
    }

    /// 收到 Broker 的 PUBACK（QoS1 发布确认）
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        // QoS1 的确认回调，发布成功统一由 didPublishMessage 通知，此处无需重复
    }

    /// 订阅结果（成功 topic 与被授予的 QoS，失败 topic 列表）
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        onQueue {
            var granted: [String: MQTTQoS] = [:]
            for (key, value) in success {
                guard let topic = key as? String else { continue }
                // value 为 NSNumber 包装的 QoS 原始值
                if let raw = value as? Int, let qos = MQTTQoS(rawValue: raw) {
                    granted[topic] = qos
                } else {
                    granted[topic] = self.activeSubscriptions[topic] ?? .atLeastOnce
                }
            }
            self.notifySubscribe(success: granted, failed: failed)
        }
    }

    /// 取消订阅成功
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        onQueue {
            self.notifyUnsubscribe(topics: topics)
        }
    }

    /// 心跳 PING 已发出
    func mqttDidPing(_ mqtt: CocoaMQTT) {}

    /// 收到 Broker 的 PONG 响应
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}

    /// 连接断开（主动或异常）
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        onQueue {
            self.cancelConnectTimeout()
            self.cancelDisconnectFallback()
            // 主动断开：状态机由 disconnect() 推进到 disconnecting，这里收尾到 disconnected
            if case .disconnecting = self.connectionState {
                self.client = nil
                self.connectionState = .disconnected
                self.notifyDisconnected(error: nil)
                return
            }
            // CONNACK 被拒绝的收尾（didConnectAck 已通知过），应用层拒绝不进入重连
            if self.isConnectRejected {
                self.isConnectRejected = false
                self.client = nil
                return
            }
            // 连接超时等场景已先行进入重连流程，此处跳过避免重复计数
            if case .reconnecting = self.connectionState { return }
            // 异常断开：进入自动重连流程（或宣告失败）
            self.handleUnexpectedDisconnect(error: err)
        }
    }

    /// 手动校验 SSL/TLS 服务端证书（仅 allowUntrustCA = true 时被库触发）
    /// - Warning: 若不实现此回调，completionHandler 不会被调用，TLS 握手将挂起直至超时
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        let allowed = onQueueSync { self.configuration.enableTLS && self.configuration.allowUntrustCA }
        completionHandler(allowed)
    }
}
