//
//  ALBroadcastManager.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/21.
//

import UIKit

// MARK: - 广播数据模型
struct ALBroadcastItem {
    let id: String
    let title: String
    let message: String
    let icon: String?
    let backgroundColor: UIColor
    let textColor: UIColor
    
    init(title: String, message: String, icon: String? = nil, backgroundColor: UIColor = .systemBlue, textColor: UIColor = .white) {
        self.id = UUID().uuidString
        self.title = title
        self.message = message
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
}

// MARK: - 广播跑道配置
struct ALBroadcastConfig {
    /// 最大广播跑道数量
    var maxRunways: Int = 3
    /// 进入动画时长
    var enterAnimationDuration: TimeInterval = 0.6
    /// 中央停留时长
    var centerHoverDuration: TimeInterval = 1.0
    /// 退出动画时长
    var exitAnimationDuration: TimeInterval = 0.5
    /// 距离顶部的偏移量
    var offsetFromTop: CGFloat = 60
    
    // 样式配置
    var runwayHeight: CGFloat = 64
    var runwaySpacing: CGFloat = 8
    var cornerRadius: CGFloat = 32
    var defaultBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.2)
    var defaultTextColor: UIColor = .white
    
    // 边距配置
    var horizontalMargin: CGFloat = 20
    var iconSize: CGSize = CGSize(width: 48, height: 48)
    var iconSpacing: CGFloat = 8
    var titleSpacing: CGFloat = 4
}

// MARK: - 广播跑道视图
class ALBroadcastView: UIView {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    
    var broadcastItem: ALBroadcastItem?
    private var config: ALBroadcastConfig
    
    init(config: ALBroadcastConfig = ALBroadcastConfig()) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.config = ALBroadcastConfig()
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 容器视图设置
        containerView.backgroundColor = config.defaultBackgroundColor
        containerView.layer.cornerRadius = config.cornerRadius
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        // 图标设置
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.backgroundColor = .clear
        iconImageView.isHidden = true // 默认隐藏，有图标时才显示
        
        // 标题标签设置
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = config.defaultTextColor
        titleLabel.numberOfLines = 1
        
        // 消息标签设置
        messageLabel.font = UIFont.systemFont(ofSize: 12)
        messageLabel.textColor = config.defaultTextColor
        messageLabel.numberOfLines = 2
        
        // 垂直堆叠视图设置
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStackView.axis = .vertical
        textStackView.spacing = config.titleSpacing
        textStackView.alignment = .leading
        textStackView.distribution = .fill
        
        // 水平堆叠视图设置
        stackView.axis = .horizontal
        stackView.spacing = config.iconSpacing
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(textStackView)
        
        containerView.addSubview(stackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 容器视图约束
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 堆叠视图约束
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: config.horizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -config.horizontalMargin),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 图标约束
            iconImageView.widthAnchor.constraint(equalToConstant: config.iconSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: config.iconSize.height)
        ])
    }
    
    func configure(with broadcastItem: ALBroadcastItem) {
        self.broadcastItem = broadcastItem
        
        titleLabel.text = broadcastItem.title
        messageLabel.text = broadcastItem.message
        containerView.backgroundColor = broadcastItem.backgroundColor
        titleLabel.textColor = broadcastItem.textColor
        messageLabel.textColor = broadcastItem.textColor
        
        // 处理图标
        if let icon = broadcastItem.icon, !icon.isEmpty {
            iconImageView.isHidden = false
            // 这里可以设置图标图片，暂时用占位颜色
            iconImageView.backgroundColor = broadcastItem.textColor.withAlphaComponent(0.3)
            iconImageView.layer.cornerRadius = config.iconSize.width / 2
        } else {
            iconImageView.isHidden = true
        }
    }
    
    deinit {
        print("deinit ---- \(type(of: self))")
    }
}

// MARK: - 广播跑道状态枚举
enum ALBroadcastState {
    case idle, entering, centering, exiting
}

// MARK: - 广播跑道信息
class ALBroadcastRunwayInfo {
    let runway: ALBroadcastView
    var state: ALBroadcastState = .idle
    var centerTimer: Timer?
    var animator: UIViewPropertyAnimator?
    
    init(runway: ALBroadcastView) {
        self.runway = runway
    }
    
    func cancelCenterTimer() {
        centerTimer?.invalidate()
        centerTimer = nil
    }
    
    func cancelAnimator() {
        animator?.stopAnimation(true)
        animator = nil
    }
    
    func reset() {
        cancelAnimator()
        cancelCenterTimer()
        runway.isHidden = true
        runway.alpha = 1.0
        runway.transform = .identity
        runway.broadcastItem = nil
        state = .idle
    }
    
    deinit {
        cancelAnimator()
        cancelCenterTimer()
    }
}

// MARK: - 广播动画管理器
class ALBroadcastManager {
    private var config: ALBroadcastConfig
    private unowned var parentView: UIView
    private var runwayInfos: [ALBroadcastRunwayInfo] = []
    private var broadcastQueue: [ALBroadcastItem] = []
    
    init(parentView: UIView, config: ALBroadcastConfig = ALBroadcastConfig()) {
        self.parentView = parentView
        self.config = config
    }
    
    // MARK: - 公开方法
    
    /// 添加广播消息
    /// - Parameter broadcastItem: 广播内容
    func showBroadcast(_ broadcastItem: ALBroadcastItem) {
        broadcastQueue.append(broadcastItem)
        processQueue()
    }
    
    /// 更新配置
    /// - Parameter newConfig: 新的配置
    func updateConfig(_ newConfig: ALBroadcastConfig) {
        self.config = newConfig
    }
    
    /// 清理所有广播和队列
    func clearAllBroadcasts() {
        broadcastQueue.removeAll()
        runwayInfos.forEach { info in
            info.reset()
            info.runway.removeFromSuperview()
        }
        runwayInfos.removeAll()
    }
    
    // MARK: - 私有方法
    
    private func processQueue() {
        guard !broadcastQueue.isEmpty else { return }
        
        if let runwayInfo = findAvailableRunway() {
            let broadcastItem = broadcastQueue.removeFirst()
            displayBroadcast(broadcastItem, in: runwayInfo)
        } else if runwayInfos.count < config.maxRunways {
            let broadcastItem = broadcastQueue.removeFirst()
            let newRunwayInfo = createNewRunway()
            runwayInfos.append(newRunwayInfo)
            displayBroadcast(broadcastItem, in: newRunwayInfo)
        }
        // 如果没有可用跑道且达到最大数量，广播会留在队列中等待
    }
    
    private func findAvailableRunway() -> ALBroadcastRunwayInfo? {
        return runwayInfos.first { $0.state == .idle }
    }
    
    private func displayBroadcast(_ broadcastItem: ALBroadcastItem, in runwayInfo: ALBroadcastRunwayInfo) {
        runwayInfo.state = .entering
        let runway = runwayInfo.runway
        
        runway.configure(with: broadcastItem)
        runway.isHidden = false
        
        // 初始状态：在屏幕右侧外，完全透明
        let startTransform = CGAffineTransform(translationX: parentView.bounds.width, y: 0)
        runway.transform = startTransform
        runway.alpha = 0.0
        
        // 创建进入动画 - 从右侧滑入到中央
        let enterAnimator = UIViewPropertyAnimator(duration: config.enterAnimationDuration, dampingRatio: 0.8) {
            runway.transform = .identity
            runway.alpha = 1.0
        }
        
        enterAnimator.addCompletion { position in
            if position == .end {
                runwayInfo.state = .centering
                self.startCenterTimer(for: runwayInfo)
            }
        }
        
        runwayInfo.animator = enterAnimator
        enterAnimator.startAnimation()
    }
    
    private func startCenterTimer(for runwayInfo: ALBroadcastRunwayInfo) {
        runwayInfo.cancelCenterTimer()
        runwayInfo.centerTimer = Timer.scheduledTimer(withTimeInterval: config.centerHoverDuration, repeats: false) { [weak self] _ in
            self?.exitBroadcast(runwayInfo)
        }
    }
    
    private func exitBroadcast(_ runwayInfo: ALBroadcastRunwayInfo) {
        guard runwayInfo.state == .centering else { return }
        
        runwayInfo.state = .exiting
        let runway = runwayInfo.runway
        
        // 创建退出动画 - 从中央滑出到左侧
        let exitAnimator = UIViewPropertyAnimator(duration: config.exitAnimationDuration, curve: .easeIn) {
            let endTransform = CGAffineTransform(translationX: -self.parentView.bounds.width, y: 0)
            runway.transform = endTransform
            runway.alpha = 0.0
        }
        
        exitAnimator.addCompletion { position in
            if position == .end {
                runwayInfo.reset()
                self.processQueue()
            }
        }
        
        runwayInfo.animator = exitAnimator
        exitAnimator.startAnimation()
    }
    
    private func createNewRunway() -> ALBroadcastRunwayInfo {
        let runway = ALBroadcastView(config: config)
        runway.isHidden = true
        runway.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(runway)
        
        let runwayIndex = runwayInfos.count
        let topOffset = config.offsetFromTop + CGFloat(runwayIndex) * (config.runwayHeight + config.runwaySpacing)
        
        NSLayoutConstraint.activate([
            runway.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: config.horizontalMargin),
            runway.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -config.horizontalMargin),
            runway.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: topOffset),
            runway.heightAnchor.constraint(equalToConstant: config.runwayHeight)
        ])
        
        return ALBroadcastRunwayInfo(runway: runway)
    }
}

// MARK: - 使用示例
/*
 使用方法：
 
 // 1. 初始化管理器
 let broadcastManager = ALBroadcastManager(parentView: self.view)
 
 // 2. 自定义配置（可选）
 var config = ALBroadcastConfig()
 config.maxRunways = 2
 config.centerHoverDuration = 2.0
 config.offsetFromTop = 100
 broadcastManager.updateConfig(config)
 
 // 3. 显示广播
 let broadcast1 = ALBroadcastItem(
     title: "系统通知",
     message: "您有新的消息，请及时查看",
     backgroundColor: .systemRed
 )
 broadcastManager.showBroadcast(broadcast1)
 
 let broadcast2 = ALBroadcastItem(
     title: "活动提醒",
     message: "限时活动即将开始，快来参与吧！",
     icon: "activity_icon",
     backgroundColor: .systemGreen
 )
 broadcastManager.showBroadcast(broadcast2)
 
 // 4. 清理所有广播（可选）
 broadcastManager.clearAllBroadcasts()
 */
