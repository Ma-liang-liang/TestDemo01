//
//  BluetoothDemoController.swift
//  TestDemo01
//
//  Created by Codex on 2026/7/11.
//

/// 蓝牙 Demo 的 UI 控制器。
/// 界面布局：
///   ┌─────────────────────┐
///   │  连接与状态（状态卡片）  │  ← 蓝牙状态 / 已连接设备 / 特征就绪 / 传输进度
///   ├─────────────────────┤
///   │  操作（按钮卡片）       │  ← 扫描 / 停止扫描 / 断开 / 发命令 / 发大数据
///   ├─────────────────────┤
///   │  附近设备（设备列表）    │  ← 扫描结果，点击行可连接
///   ├─────────────────────┤
///   │  优化日志（日志文本）    │  ← 实时显示运行日志
///   └─────────────────────┘
/// 通过 Combine 绑定 ViewModel 的 @Published 属性来驱动 UI 更新。

import Combine
import SnapKit
import UIKit

final class BluetoothDemoController: SKBaseController {

    // MARK: - 依赖

    /// ViewModel，负责蓝牙业务逻辑和数据绑定
    private let viewModel = BluetoothDemoViewModel()

    // MARK: - UI 控件

    /// 整体滚动容器（内容可能超出屏幕）
    private let scrollView = UIScrollView()
    /// 垂直排列的卡片容器
    private let contentStack = UIStackView()
    /// 蓝牙适配器状态标签
    private let stateLabel = UILabel()
    /// 已连接设备名称标签
    private let connectedLabel = UILabel()
    /// 特征就绪状态标签
    private let readyLabel = UILabel()
    /// 传输进度标签
    private let progressLabel = UILabel()
    /// 扫描结果设备列表
    private let devicesTableView = UITableView(frame: .zero, style: .plain)
    /// 日志输出文本框
    private let logsTextView = UITextView()
    /// 扫描按钮
    private let scanButton = UIButton(type: .system)
    /// 停止扫描按钮
    private let stopScanButton = UIButton(type: .system)
    /// 断开连接按钮
    private let disconnectButton = UIButton(type: .system)
    /// 发送小命令按钮
    private let sendCommandButton = UIButton(type: .system)
    /// 发送大数据按钮
    private let sendLargeDataButton = UIButton(type: .system)

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.titleLabel.text = "蓝牙通信优化"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        bindViewModel()
    }

    deinit {
        // 页面销毁时停止扫描，避免后台浪费蓝牙资源
        viewModel.stopScan()
    }

    // MARK: - UI 搭建

    /// 搭建整体 UI 结构：ScrollView → StackView → 各卡片
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

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

        // 依次添加四张卡片
        contentStack.addArrangedSubview(makeStatusCard())
        contentStack.addArrangedSubview(makeActionCard())
        contentStack.addArrangedSubview(makeDeviceCard())
        contentStack.addArrangedSubview(makeLogCard())

        // 设备列表配置
        devicesTableView.dataSource = self
        devicesTableView.delegate = self
        devicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "BluetoothDeviceCell")
        devicesTableView.layer.cornerRadius = 8
        devicesTableView.isScrollEnabled = false   // 禁用内部滚动，由外层 ScrollView 统一管理
        devicesTableView.rowHeight = 56
        devicesTableView.snp.makeConstraints { make in
            make.height.equalTo(224)               // 固定高度：4 行 × 56pt
        }

        // 日志文本框配置
        logsTextView.isEditable = false
        logsTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logsTextView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        logsTextView.layer.cornerRadius = 8
        logsTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        logsTextView.snp.makeConstraints { make in
            make.height.equalTo(220)
        }
    }

    // MARK: - ViewModel 绑定

    /// 使用 Combine 将 ViewModel 的 @Published 属性绑定到 UI 控件
    private func bindViewModel() {
        // 蓝牙状态
        viewModel.$stateText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.stateLabel.text = "蓝牙状态：\(text)"
            }
            .store(in: &cancelables)

        // 已连接设备名称
        viewModel.$connectedDeviceName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.connectedLabel.text = "当前连接：\(text)"
            }
            .store(in: &cancelables)

        // 特征就绪状态
        viewModel.$readyText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.readyLabel.text = text
            }
            .store(in: &cancelables)

        // 传输进度
        viewModel.$progressText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.progressLabel.text = "传输进度：\(text)"
            }
            .store(in: &cancelables)

        // 设备列表变化时刷新表格并更新高度
        viewModel.$devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.devicesTableView.reloadData()
                // 动态高度：至少 1 行，最多 10 行，每行 56pt
                let rowCount = max(devices.count, 1)
                let height = CGFloat(min(rowCount, 10)) * 56
                self?.devicesTableView.snp.updateConstraints { make in
                    make.height.equalTo(height)
                }
            }
            .store(in: &cancelables)

        // 日志更新时刷新文本框
        viewModel.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                self?.logsTextView.text = logs.joined(separator: "\n")
            }
            .store(in: &cancelables)

        // 按钮状态绑定：根据扫描/连接/就绪状态统一启用或禁用
        Publishers.CombineLatest3(viewModel.$isScanning, viewModel.$isConnected, viewModel.$isReady)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scanning, connected, ready in
                self?.scanButton.isEnabled = !scanning && !connected
                self?.stopScanButton.isEnabled = scanning
                self?.disconnectButton.isEnabled = connected
                self?.sendCommandButton.isEnabled = ready
                self?.sendLargeDataButton.isEnabled = ready
            }
            .store(in: &cancelables)
    }

    // MARK: - 卡片构建

    /// 构建"连接与状态"卡片
    private func makeStatusCard() -> UIView {
        let card = makeCard(title: "连接与状态")
        [stateLabel, connectedLabel, readyLabel, progressLabel].forEach {
            $0.font = .systemFont(ofSize: 14)
            $0.textColor = .label
            $0.numberOfLines = 0
            card.stack.addArrangedSubview($0)
        }
        return card.container
    }

    /// 构建"操作"卡片，包含所有操作按钮
    private func makeActionCard() -> UIView {
        let card = makeCard(title: "操作")
        let rows = [
            makeButtonRow([scanButton, stopScanButton, disconnectButton]),
            makeButtonRow([sendCommandButton, sendLargeDataButton])
        ]

        // 配置按钮标题和点击事件
        configureButton(scanButton, title: "扫描", action: #selector(onScan))
        configureButton(stopScanButton, title: "停止扫描", action: #selector(onStopScan))
        configureButton(disconnectButton, title: "断开", action: #selector(onDisconnect))
        configureButton(sendCommandButton, title: "发命令", action: #selector(onSendCommand))
        configureButton(sendLargeDataButton, title: "发大数据", action: #selector(onSendLargeData))

        rows.forEach { card.stack.addArrangedSubview($0) }
        return card.container
    }

    /// 构建"附近设备"卡片，内含设备列表
    private func makeDeviceCard() -> UIView {
        let card = makeCard(title: "附近设备")
        card.stack.addArrangedSubview(devicesTableView)
        return card.container
    }

    /// 构建"优化日志"卡片，内含日志文本框
    private func makeLogCard() -> UIView {
        let card = makeCard(title: "优化日志")
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

    /// 将多个按钮横向排列成一行
    private func makeButtonRow(_ buttons: [UIButton]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
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

    /// 点击"扫描"按钮
    @objc private func onScan() {
        viewModel.startScan()
    }

    /// 点击"停止扫描"按钮
    @objc private func onStopScan() {
        viewModel.stopScan()
    }

    /// 点击"断开"按钮
    @objc private func onDisconnect() {
        viewModel.disconnect()
    }

    /// 点击"发命令"按钮
    @objc private func onSendCommand() {
        viewModel.sendSmallCommand()
    }

    /// 点击"发大数据"按钮
    @objc private func onSendLargeData() {
        viewModel.sendLargePayload()
    }
}

// MARK: - 设备列表数据源与代理

extension BluetoothDemoController: UITableViewDataSource, UITableViewDelegate {

    /// 行数：至少 1 行（空状态时显示提示文字）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(viewModel.devices.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothDeviceCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        // 空状态：显示扫描提示
        guard viewModel.devices.indices.contains(indexPath.row) else {
            content.text = "点击\"扫描\"查找附近 BLE 设备"
            content.secondaryText = nil
            cell.contentConfiguration = content
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
        }

        // 正常状态：显示设备名称和 RSSI
        let device = viewModel.devices[indexPath.row]
        content.text = device.name
        content.secondaryText = "RSSI: \(device.rssi)  ID: \(device.identifier.uuidString)"
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    /// 点击设备行 → 连接该设备
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.connectDevice(at: indexPath.row)
    }
}
