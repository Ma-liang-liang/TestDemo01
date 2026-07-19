//
//  MQTTDemoController.swift
//  TestDemo01
//
//  Created by Qoder on 2026/7/19.
//

/// MQTT Demo 的 UI 控制器。
/// 界面布局：
///   ┌─────────────────────┐
///   │  连接配置（输入卡片）    │  ← Broker 地址 / 端口 / ClientID
///   ├─────────────────────┤
///   │  连接与状态（状态卡片）  │  ← 连接状态 / Broker / 已订阅 / 指标
///   ├─────────────────────┤
///   │  主题与消息（输入卡片）  │  ← 订阅 topic / 发布 topic / 消息 / QoS
///   ├─────────────────────┤
///   │  操作（按钮卡片）       │  ← 连接 / 断开 / 订阅 / 退订 / 发布
///   ├─────────────────────┤
///   │  消息日志（日志文本）    │  ← 实时显示收发消息与运行日志
///   └─────────────────────┘
/// 通过 Combine 绑定 ViewModel 的 @Published 属性来驱动 UI 更新。
/// 默认连接 EMQX 公共测试 Broker（broker.emqx.io:1883），
/// 订阅与发布使用同一 topic 时即可在页面上自收自发验证链路。

import Combine
import SnapKit
import UIKit

final class MQTTDemoController: SKBaseController {

    // MARK: - 依赖

    /// ViewModel，负责 MQTT 业务逻辑和数据绑定
    private let viewModel = MQTTDemoViewModel()

    // MARK: - UI 控件

    /// 整体滚动容器（内容可能超出屏幕）
    private let scrollView = UIScrollView()
    /// 垂直排列的卡片容器
    private let contentStack = UIStackView()
    /// Broker 地址输入框
    private let hostField = UITextField()
    /// 端口输入框
    private let portField = UITextField()
    /// ClientID 输入框
    private let clientIDField = UITextField()
    /// 连接状态标签
    private let stateLabel = UILabel()
    /// 当前 Broker 标签
    private let brokerLabel = UILabel()
    /// 已订阅 topic 标签
    private let subscribedLabel = UILabel()
    /// 运行时指标标签
    private let metricsLabel = UILabel()
    /// 订阅 topic 输入框
    private let subTopicField = UITextField()
    /// 发布 topic 输入框
    private let pubTopicField = UITextField()
    /// 消息内容输入框
    private let messageField = UITextField()
    /// QoS 选择器
    private let qosSegmented = UISegmentedControl(items: ["QoS 0", "QoS 1", "QoS 2"])
    /// 日志输出文本框
    private let logsTextView = UITextView()
    /// 连接按钮
    private let connectButton = UIButton(type: .system)
    /// 断开连接按钮
    private let disconnectButton = UIButton(type: .system)
    /// 订阅按钮
    private let subscribeButton = UIButton(type: .system)
    /// 退订按钮
    private let unsubscribeButton = UIButton(type: .system)
    /// 发布按钮
    private let publishButton = UIButton(type: .system)

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.titleLabel.text = "MQTT 通信"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        bindViewModel()
    }

    deinit {
        // 页面销毁时断开连接，避免后台占用长连接
        viewModel.disconnect()
    }

    // MARK: - UI 搭建

    /// 搭建整体 UI 结构：ScrollView → StackView → 各卡片
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        // 点击空白处收起键盘
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onDismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)

        // ScrollView 填充导航栏以下区域
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // StackView 垂直排列，内边距 16pt
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }

        // 依次添加五张卡片
        contentStack.addArrangedSubview(makeConfigCard())
        contentStack.addArrangedSubview(makeStatusCard())
        contentStack.addArrangedSubview(makeTopicCard())
        contentStack.addArrangedSubview(makeActionCard())
        contentStack.addArrangedSubview(makeLogCard())

        // 日志文本框配置
        logsTextView.isEditable = false
        logsTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logsTextView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        logsTextView.layer.cornerRadius = 8
        logsTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        logsTextView.snp.makeConstraints { make in
            make.height.equalTo(260)
        }
    }

    // MARK: - ViewModel 绑定

    /// 使用 Combine 将 ViewModel 的 @Published 属性绑定到 UI 控件
    private func bindViewModel() {
        // 连接状态
        viewModel.$stateText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.stateLabel.text = "连接状态：\(text)"
            }
            .store(in: &cancelables)

        // 当前 Broker
        viewModel.$brokerText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.brokerLabel.text = "Broker：\(text)"
            }
            .store(in: &cancelables)

        // 已订阅 topic
        viewModel.$subscribedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.subscribedLabel.text = "已订阅：\(text)"
            }
            .store(in: &cancelables)

        // 运行时指标
        viewModel.$metricsText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.metricsLabel.text = "指标：\(text)"
            }
            .store(in: &cancelables)

        // 日志更新时刷新文本框
        viewModel.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                self?.logsTextView.text = logs.joined(separator: "\n")
            }
            .store(in: &cancelables)

        // 按钮状态绑定：根据连接状态统一启用或禁用
        Publishers.CombineLatest(viewModel.$isConnected, viewModel.$isConnecting)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected, connecting in
                self?.connectButton.isEnabled = !connected && !connecting
                self?.disconnectButton.isEnabled = connected || connecting
                self?.subscribeButton.isEnabled = connected
                self?.unsubscribeButton.isEnabled = connected
                self?.publishButton.isEnabled = connected
            }
            .store(in: &cancelables)
    }

    // MARK: - 卡片构建

    /// 构建"连接配置"卡片，包含 Broker 地址、端口、ClientID 输入
    private func makeConfigCard() -> UIView {
        let card = makeCard(title: "连接配置")
        configureField(hostField, placeholder: "Broker 地址", text: "broker.emqx.io", keyboard: .URL)
        configureField(portField, placeholder: "端口", text: "1883", keyboard: .numberPad)
        configureField(clientIDField, placeholder: "ClientID（留空自动生成）", text: "", keyboard: .asciiCapable)
        card.stack.addArrangedSubview(makeFieldRow(title: "Host", field: hostField))
        card.stack.addArrangedSubview(makeFieldRow(title: "Port", field: portField))
        card.stack.addArrangedSubview(makeFieldRow(title: "ClientID", field: clientIDField))
        return card.container
    }

    /// 构建"连接与状态"卡片
    private func makeStatusCard() -> UIView {
        let card = makeCard(title: "连接与状态")
        [stateLabel, brokerLabel, subscribedLabel, metricsLabel].forEach {
            $0.font = .systemFont(ofSize: 14)
            $0.textColor = .label
            $0.numberOfLines = 0
            card.stack.addArrangedSubview($0)
        }
        return card.container
    }

    /// 构建"主题与消息"卡片，包含订阅/发布 topic、消息内容与 QoS 选择
    private func makeTopicCard() -> UIView {
        let card = makeCard(title: "主题与消息")
        configureField(subTopicField, placeholder: "订阅 topic（支持 + 与 # 通配符）", text: "testdemo/ios/message", keyboard: .asciiCapable)
        configureField(pubTopicField, placeholder: "发布 topic", text: "testdemo/ios/message", keyboard: .asciiCapable)
        configureField(messageField, placeholder: "消息内容", text: "Hello MQTT", keyboard: .default)
        qosSegmented.selectedSegmentIndex = 1
        card.stack.addArrangedSubview(subTopicField)
        card.stack.addArrangedSubview(pubTopicField)
        card.stack.addArrangedSubview(messageField)
        card.stack.addArrangedSubview(qosSegmented)
        return card.container
    }

    /// 构建"操作"卡片，包含所有操作按钮
    private func makeActionCard() -> UIView {
        let card = makeCard(title: "操作")
        let rows = [
            makeButtonRow([connectButton, disconnectButton]),
            makeButtonRow([subscribeButton, unsubscribeButton]),
            makeButtonRow([publishButton])
        ]

        // 配置按钮标题和点击事件
        configureButton(connectButton, title: "连接", action: #selector(onConnect))
        configureButton(disconnectButton, title: "断开", action: #selector(onDisconnect))
        configureButton(subscribeButton, title: "订阅", action: #selector(onSubscribe))
        configureButton(unsubscribeButton, title: "退订", action: #selector(onUnsubscribe))
        configureButton(publishButton, title: "发布", action: #selector(onPublish))

        rows.forEach { card.stack.addArrangedSubview($0) }
        return card.container
    }

    /// 构建"消息日志"卡片，内含日志文本框
    private func makeLogCard() -> UIView {
        let card = makeCard(title: "消息日志")
        card.stack.addArrangedSubview(logsTextView)
        return card.container
    }

    /// 通用卡片构建器，返回容器视图和内部 StackView
    /// - Parameter title: 卡片标题
    /// - Returns: (容器视图, 内部垂直 StackView)
    private func makeCard(title: String) -> (container: UIView, stack: UIStackView) {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label

        let stack = UIStackView(arrangedSubviews: [titleLabel])
        stack.axis = .vertical
        stack.spacing = 10
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        return (container, stack)
    }

    /// 构建"标题 + 输入框"的水平行
    private func makeFieldRow(title: String, field: UITextField) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .horizontal
        stack.spacing = 10
        return stack
    }

    /// 将多个按钮横向排列成一行
    private func makeButtonRow(_ buttons: [UIButton]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }

    /// 统一配置输入框样式
    private func configureField(_ field: UITextField, placeholder: String, text: String, keyboard: UIKeyboardType) {
        field.placeholder = placeholder
        field.text = text
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 14)
        field.keyboardType = keyboard
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
    }

    /// 统一配置按钮样式和点击事件
    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)
        button.configuration = configuration
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    // MARK: - 按钮事件

    /// 点击"连接"按钮
    @objc private func onConnect() {
        view.endEditing(true)
        viewModel.connect(host: hostField.text ?? "",
                          portText: portField.text ?? "",
                          clientID: clientIDField.text ?? "")
    }

    /// 点击"断开"按钮
    @objc private func onDisconnect() {
        viewModel.disconnect()
    }

    /// 点击"订阅"按钮
    @objc private func onSubscribe() {
        view.endEditing(true)
        viewModel.subscribe(topic: subTopicField.text ?? "")
    }

    /// 点击"退订"按钮
    @objc private func onUnsubscribe() {
        view.endEditing(true)
        viewModel.unsubscribe(topic: subTopicField.text ?? "")
    }

    /// 点击"发布"按钮
    @objc private func onPublish() {
        view.endEditing(true)
        viewModel.publish(topic: pubTopicField.text ?? "",
                          message: messageField.text ?? "",
                          qosIndex: qosSegmented.selectedSegmentIndex)
    }

    /// 点击空白处收起键盘
    @objc private func onDismissKeyboard() {
        view.endEditing(true)
    }
}
