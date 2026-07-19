//
//  MQTTDemoViewModel.swift
//  TestDemo01
//
//  Created by Qoder on 2026/7/19.
//

/// MQTT Demo 的 ViewModel，作为 UI 控制器与 MQTTManager 之间的中间层。
/// 职责：
/// 1. 持有 MQTTManager 单例并注册为 delegate
/// 2. 将 MQTT 回调转换为 @Published 属性供 UI 绑定
/// 3. 暴露简洁的业务方法（连接、断开、订阅、退订、发布）
/// 4. 维护日志队列，方便用户观察运行时行为

import Combine
import Foundation

final class MQTTDemoViewModel: NSObject, ObservableObject {

    // MARK: - 常量

    /// 日志时间格式化器（复用，避免每次 addLog 都新建）
    private static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: - UI 绑定属性

    /// 连接状态文本（如"已连接"、"重连中（第2次）"等）
    @Published private(set) var stateText = "未连接"
    /// 当前 Broker 地址文本
    @Published private(set) var brokerText = "broker.emqx.io:1883"
    /// 已订阅 topic 列表文本
    @Published private(set) var subscribedText = "无"
    /// 运行时指标文本（连接耗时、收发计数、重连次数）
    @Published private(set) var metricsText = "-"
    /// 运行时日志列表，最新日志在数组头部
    @Published private(set) var logs: [String] = []
    /// 是否已连接
    @Published private(set) var isConnected = false
    /// 是否处于连接流程中（连接中/重连中/断开中）
    @Published private(set) var isConnecting = false

    // MARK: - 依赖

    /// MQTT 管理器，默认使用单例
    private let mqttManager: MQTTManager

    // MARK: - 初始化

    /// - Parameter mqttManager: MQTT 管理器，默认使用单例（测试时可注入 mock）
    init(mqttManager: MQTTManager = .shared) {
        self.mqttManager = mqttManager
        super.init()
        // 注册为 delegate，接收 MQTT 事件回调
        mqttManager.addDelegate(self)
    }

    deinit {
        // 移除 delegate，避免野指针回调
        mqttManager.removeDelegate(self)
    }

    // MARK: - 业务方法

    /// 按页面输入建立连接
    /// - Parameters:
    ///   - host: Broker 地址，为空则使用默认公共测试 Broker
    ///   - portText: 端口文本，非法时使用 1883
    ///   - clientID: 客户端标识，为空则自动生成
    func connect(host: String, portText: String, clientID: String) {
        let finalHost = host.isEmpty ? "broker.emqx.io" : host
        let finalPort = UInt16(portText) ?? 1883
        let finalClientID = clientID.isEmpty ? "ios-\(UUID().uuidString.prefix(8).lowercased())" : clientID

        mqttManager.update(configuration: MQTTConfiguration(
            host: finalHost,
            port: finalPort,
            clientID: finalClientID,
            keepAlive: 60,
            cleanSession: true,
            connectTimeout: 10,
            reconnectMaxAttempts: 5,
            reconnectBaseDelay: 1,
            willMessage: MQTTMessage(
                topic: "testdemo/ios/status",
                payload: Data("client \(finalClientID) offline".utf8),
                qos: .atLeastOnce
            )
        ))
        brokerText = "\(finalHost):\(finalPort)"
        addLog("连接 \(finalHost):\(finalPort)，clientID：\(finalClientID)，异常断开会按指数退避+随机抖动重连。")
        mqttManager.connect()
    }

    /// 主动断开当前连接（不触发自动重连）
    func disconnect() {
        mqttManager.disconnect()
        addLog("主动断开：主动断开不触发自动重连。")
    }

    /// 订阅主题
    /// - Parameter topic: 主题过滤串（支持通配符 + 与 #）
    func subscribe(topic: String) {
        guard !topic.isEmpty else {
            addLog("订阅失败：topic 不能为空。")
            return
        }
        mqttManager.subscribe(topic: topic, qos: .atLeastOnce)
        addLog("订阅 \(topic)：重连成功后会自动恢复全部订阅。")
    }

    /// 取消订阅主题
    /// - Parameter topic: 已订阅的主题过滤串
    func unsubscribe(topic: String) {
        guard !topic.isEmpty else {
            addLog("退订失败：topic 不能为空。")
            return
        }
        mqttManager.unsubscribe(topic: topic)
        addLog("退订 \(topic)。")
    }

    /// 发布消息
    /// - Parameters:
    ///   - topic: 目标主题
    ///   - message: 消息文本
    ///   - qosIndex: QoS 选择下标（0/1/2）
    func publish(topic: String, message: String, qosIndex: Int) {
        guard !topic.isEmpty, !message.isEmpty else {
            addLog("发布失败：topic 与消息均不能为空。")
            return
        }
        let qos = MQTTQoS.allCases[safe: qosIndex] ?? .atLeastOnce
        mqttManager.publish(message, topic: topic, qos: qos)
        addLog("发布 → \(topic)（QoS \(qos.rawValue)）：\(message)")
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
}

// MARK: - MQTTManagerDelegate

/// MQTT 事件回调实现，将底层事件转换为 @Published 属性和日志。
extension MQTTDemoViewModel: MQTTManagerDelegate {

    /// 连接状态变化（如 connecting → connected → reconnecting）
    func mqttManager(_ manager: MQTTManager, didChangeConnectionState state: MQTTConnectionState) {
        switch state {
        case .disconnected:
            stateText = "未连接"
            isConnected = false
            isConnecting = false
        case .connecting:
            stateText = "连接中…"
            isConnected = false
            isConnecting = true
        case .connected:
            stateText = "已连接"
            isConnected = true
            isConnecting = false
        case .reconnecting(let attempt):
            stateText = "重连中（第 \(attempt) 次）…"
            isConnected = false
            isConnecting = true
        case .disconnecting:
            stateText = "断开中…"
            isConnected = false
            isConnecting = true
        }
        addLog("连接状态：\(stateText)")
    }

    /// 连接成功（收到 Broker CONNACK）
    func mqttManager(_ manager: MQTTManager, didConnect host: String, port: UInt16) {
        addLog("已连接 \(host):\(port)。")
    }

    /// 连接断开（主动或异常）
    func mqttManager(_ manager: MQTTManager, didDisconnect error: Error?) {
        // error 为 nil 时可能是主动断开或对端正常关闭
        let reason = error?.localizedDescription ?? "主动断开或对端关闭"
        addLog("连接断开，原因：\(reason)")
    }

    /// 收到订阅消息
    func mqttManager(_ manager: MQTTManager, didReceive message: MQTTMessage) {
        addLog("收到 ← \(message.topic)（QoS \(message.qos.rawValue)）：\(message.string ?? "<\(message.payload.count) bytes>")")
    }

    /// 消息发布成功
    func mqttManager(_ manager: MQTTManager, didPublish messageID: UInt16, topic: String) {
        addLog("发布成功：\(topic)，messageID：\(messageID)")
    }

    /// 订阅结果
    func mqttManager(_ manager: MQTTManager, didSubscribe success: [String: MQTTQoS], failed: [String]) {
        subscribedText = manager.subscribedTopics.joined(separator: "\n")
        if !success.isEmpty {
            let text = success.map { "\($0.key)(QoS \($0.value.rawValue))" }.joined(separator: ", ")
            addLog("订阅成功：\(text)")
        }
        if !failed.isEmpty {
            addLog("订阅失败：\(failed.joined(separator: ", "))")
        }
    }

    /// 取消订阅成功
    func mqttManager(_ manager: MQTTManager, didUnsubscribe topics: [String]) {
        subscribedText = manager.subscribedTopics.isEmpty ? "无" : manager.subscribedTopics.joined(separator: "\n")
        addLog("退订成功：\(topics.joined(separator: ", "))")
    }

    /// 运行时指标更新
    func mqttManager(_ manager: MQTTManager, didUpdateMetrics metrics: MQTTMetricSnapshot) {
        var parts: [String] = []
        if let cost = metrics.connectionCost {
            parts.append("连接耗时 \(String(format: "%.2f", cost))s")
        }
        parts.append("TX \(metrics.publishedCount) 条/\(metrics.transmittedBytes)B")
        parts.append("RX \(metrics.receivedCount) 条/\(metrics.receivedBytes)B")
        parts.append("重连 \(metrics.reconnectAttempts) 次")
        metricsText = parts.joined(separator: "，")
    }

    /// 发生错误
    func mqttManager(_ manager: MQTTManager, didFail error: Error) {
        addLog("错误：\(error.localizedDescription)")
    }
}

// MARK: - Array 安全下标

private extension Array {
    /// 越界时返回 nil 的安全下标
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
