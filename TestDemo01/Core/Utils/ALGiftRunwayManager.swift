//
//  ALGiftRunwayManager.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/19.
//

import UIKit

// MARK: - 礼物数据模型
struct ALGiftItem {
    let id: String
    let userName: String
    let userAvatar: String
    let giftName: String
    let giftIcon: String
    let giftCount: Int
    var comboCount: Int // 使用 var 以便更新连击数
    
    init(userName: String, userAvatar: String, giftName: String, giftIcon: String, giftCount: Int = 1, comboCount: Int = 1) {
        self.id = UUID().uuidString
        self.userName = userName
        self.userAvatar = userAvatar
        self.giftName = giftName
        self.giftIcon = giftIcon
        self.giftCount = giftCount
        self.comboCount = comboCount
    }
}

// MARK: - 礼物跑道配置
struct ALGiftRunwayConfig {
    var maxRunways: Int = 3
    var enterAnimationDuration: TimeInterval = 0.5
    var hoverDuration: TimeInterval = 1.0
    var exitAnimationDuration: TimeInterval = 0.5
    var comboAnimationDuration: TimeInterval = 0.5
    /// 礼物跑道距离顶部的偏移量
    var runwayOffsetY: CGFloat = 100
    
    var runwayHeight: CGFloat = 60
    var runwaySpacing: CGFloat = 8
    var cornerRadius: CGFloat = 30
    var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.2)
    var textColor: UIColor = .white
    var comboColor: UIColor = .orange
}

// MARK: - 礼物跑道视图
class ALGiftRunwayView: UIView {
    private let containerView = UIView()
    private let userAvatarImageView = UIImageView()
    private let userNameLabel = UILabel()
    private let giftIconImageView = UIImageView()
    private let giftNameLabel = UILabel()
    private let comboLabel = UILabel()
    
    var giftItem: ALGiftItem?
    private var config: ALGiftRunwayConfig
    
    init(config: ALGiftRunwayConfig = ALGiftRunwayConfig()) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.config = ALGiftRunwayConfig()
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        containerView.backgroundColor = config.backgroundColor
        containerView.layer.cornerRadius = config.cornerRadius
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        userAvatarImageView.contentMode = .scaleAspectFill
        userAvatarImageView.layer.cornerRadius = 20
        userAvatarImageView.clipsToBounds = true
        userAvatarImageView.backgroundColor = .lightGray
        containerView.addSubview(userAvatarImageView)
        
        userNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        userNameLabel.textColor = config.textColor
        containerView.addSubview(userNameLabel)
        
        giftIconImageView.contentMode = .scaleAspectFit
        giftIconImageView.backgroundColor = .clear
        containerView.addSubview(giftIconImageView)
        
        giftNameLabel.font = UIFont.systemFont(ofSize: 12)
        giftNameLabel.textColor = config.textColor
        containerView.addSubview(giftNameLabel)
        
        comboLabel.font = UIFont.boldSystemFont(ofSize: 22)
        comboLabel.textColor = config.comboColor
        comboLabel.textAlignment = .center
        containerView.addSubview(comboLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        userAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        giftIconImageView.translatesAutoresizingMaskIntoConstraints = false
        giftNameLabel.translatesAutoresizingMaskIntoConstraints = false
        comboLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            userAvatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            userAvatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            userAvatarImageView.widthAnchor.constraint(equalToConstant: 40),
            userAvatarImageView.heightAnchor.constraint(equalToConstant: 40),
            userNameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: 8),
            userNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            userNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            giftNameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: 8),
            giftNameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            giftNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
            giftIconImageView.leadingAnchor.constraint(equalTo: userNameLabel.trailingAnchor, constant: 8),
            giftIconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            giftIconImageView.widthAnchor.constraint(equalToConstant: 44),
            giftIconImageView.heightAnchor.constraint(equalToConstant: 44),
            comboLabel.leadingAnchor.constraint(equalTo: giftIconImageView.trailingAnchor, constant: 8),
            comboLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            comboLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            comboLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    
    func configure(with giftItem: ALGiftItem) {
        self.giftItem = giftItem
        userNameLabel.text = giftItem.userName
        giftNameLabel.text = "送出 \(giftItem.giftName)"
        comboLabel.text = "x\(giftItem.comboCount)"
        // 使用占位图
        userAvatarImageView.backgroundColor = .systemBlue
        giftIconImageView.backgroundColor = .systemOrange
    }
    
    func updateCombo(with giftItem: ALGiftItem) {
        self.giftItem = giftItem
        self.comboLabel.text = "x\(giftItem.comboCount)"
    }
    
    func playComboAnimation() {
        comboLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        UIView.animate(withDuration: config.comboAnimationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 0.8,
                       options: [.curveEaseInOut],
                       animations: { self.comboLabel.transform = .identity })
    }
    
    deinit {
        print("deinit ---- \(type(of: self))")
    }
}

// MARK: - 跑道状态枚举
enum ALRunwayState {
    case idle, entering, hovering, exiting
}

// MARK: - 跑道信息
class ALRunwayInfo {
    let runway: ALGiftRunwayView
    var state: ALRunwayState = .idle
    var hoverTimer: Timer?
    var animator: UIViewPropertyAnimator? // 持有当前正在执行的动画
    
    init(runway: ALGiftRunwayView) {
        self.runway = runway
    }
    
    func cancelHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    func cancelAnimator() {
        // 停止动画并立即完成，以便可以开始新动画
        animator?.stopAnimation(true)
        animator = nil
    }
    
    // 重置跑道到初始空闲状态
    func reset() {
        cancelAnimator()
        cancelHoverTimer()
        runway.isHidden = true
        runway.alpha = 1.0
        runway.transform = .identity
        runway.giftItem = nil
        state = .idle
    }
    
    deinit {
        cancelAnimator()
        cancelHoverTimer()
    }
}

// MARK: - 礼物跑道管理器
class ALGiftRunwayManager {
    private var config: ALGiftRunwayConfig
    private unowned var parentView: UIView
    private var runwayInfos: [ALRunwayInfo] = []
    private var giftQueue: [ALGiftItem] = []
    
    init(parentView: UIView, config: ALGiftRunwayConfig = ALGiftRunwayConfig()) {
        self.parentView = parentView
        self.config = config
    }
    
    // 添加礼物到系统
    func addGift(_ giftItem: ALGiftItem) {
        // 检查是否有相同礼物正在显示，如果是则执行连击逻辑
        if let existingRunwayInfo = findExistingRunway(for: giftItem) {
            handleComboGift(for: existingRunwayInfo, with: giftItem)
        } else {
            // 否则，将新礼物加入队列
            giftQueue.append(giftItem)
            processQueue()
        }
    }
    
    // 处理等待队列中的礼物
    private func processQueue() {
        guard !giftQueue.isEmpty else { return }
        
        if let runwayInfo = findAvailableRunway() {
            let giftItem = giftQueue.removeFirst()
            showGift(giftItem, in: runwayInfo)
        } else if runwayInfos.count < config.maxRunways {
            let giftItem = giftQueue.removeFirst()
            let newRunwayInfo = createNewRunway()
            runwayInfos.append(newRunwayInfo)
            showGift(giftItem, in: newRunwayInfo)
        }
        // 如果没有可用跑道且达到最大数量，礼物会留在队列中等待
    }
    
    private func findExistingRunway(for giftItem: ALGiftItem) -> ALRunwayInfo? {
        return runwayInfos.first { info in
            guard info.state != .idle, let currentGift = info.runway.giftItem else { return false }
            return currentGift.userName == giftItem.userName && currentGift.giftName == giftItem.giftName
        }
    }
    
    private func findAvailableRunway() -> ALRunwayInfo? {
        return runwayInfos.first { $0.state == .idle }
    }
    
    private func handleComboGift(for runwayInfo: ALRunwayInfo, with newGiftItem: ALGiftItem) {
        guard var currentGift = runwayInfo.runway.giftItem else { return }
        
        // 累加连击数并更新UI
        currentGift.comboCount += newGiftItem.comboCount
        runwayInfo.runway.updateCombo(with: currentGift)
        runwayInfo.runway.playComboAnimation()
        
        switch runwayInfo.state {
        case .entering:
            // 正在入场，动画继续，只需更新数据
            break
            
        case .hovering:
            // 正在悬停，重置悬停计时器
            startHoverTimer(for: runwayInfo)
            
        case .exiting:
            // **核心逻辑: 正在退场时，中断退场并重新入场**
            
            // 1. 立即停止当前的退场动画，视图会停在半路
            runwayInfo.cancelAnimator()
            
            // 2. 状态切换为入场
            runwayInfo.state = .entering
            
            // 3. 创建一个新的动画，从当前位置恢复到完全显示状态
            let reEnterAnimator = UIViewPropertyAnimator(duration: config.enterAnimationDuration, dampingRatio: 0.7) {
                runwayInfo.runway.transform = .identity
                runwayInfo.runway.alpha = 1.0
            }
            
            reEnterAnimator.addCompletion { position in
                if position == .end {
                    runwayInfo.state = .hovering
                    self.startHoverTimer(for: runwayInfo)
                }
            }
            
            runwayInfo.animator = reEnterAnimator
            reEnterAnimator.startAnimation()
            
        case .idle:
            // 理论上不会进入此分支
            break
        }
    }
    
    private func showGift(_ giftItem: ALGiftItem, in runwayInfo: ALRunwayInfo) {
        runwayInfo.state = .entering
        let runway = runwayInfo.runway
        
        runway.configure(with: giftItem)
        runway.isHidden = false
        
        // 初始状态：在屏幕左侧外，完全透明
        let startTransform = CGAffineTransform(translationX: -parentView.bounds.width, y: 0)
        runway.transform = startTransform
        runway.alpha = 0.0
        
        // 使用 UIViewPropertyAnimator 创建带弹簧效果的入场动画
        let enterAnimator = UIViewPropertyAnimator(duration: config.enterAnimationDuration, dampingRatio: 0.7) {
            runway.transform = .identity
            runway.alpha = 1.0
        }
        
        enterAnimator.addCompletion { position in
            if position == .end {
                runwayInfo.state = .hovering
                self.startHoverTimer(for: runwayInfo)
            }
        }
        
        runwayInfo.animator = enterAnimator
        enterAnimator.startAnimation()
    }
    
    private func hideGift(_ runwayInfo: ALRunwayInfo) {
        guard runwayInfo.state == .hovering else { return }
        
        runwayInfo.state = .exiting
        let runway = runwayInfo.runway
        
        // 创建对称的退场动画（原路返回）
        let exitAnimator = UIViewPropertyAnimator(duration: config.exitAnimationDuration, curve: .easeIn) {
            // 动画目标：回到屏幕左侧外，并变为透明
            let endTransform = CGAffineTransform(translationX: -self.parentView.bounds.width, y: 0)
            runway.transform = endTransform
            runway.alpha = 0.0
        }
        
        exitAnimator.addCompletion { position in
            // 只有当动画正常结束时才重置跑道
            // 如果被中途打断，completion block 不会以 .end 状态被调用
            if position == .end {
                runwayInfo.reset()
                self.processQueue() // 检查队列中是否有等待的礼物
            }
        }
        
        runwayInfo.animator = exitAnimator
        exitAnimator.startAnimation()
    }
    
    private func startHoverTimer(for runwayInfo: ALRunwayInfo) {
        runwayInfo.cancelHoverTimer() // 总是先取消旧的
        runwayInfo.hoverTimer = Timer.scheduledTimer(withTimeInterval: config.hoverDuration, repeats: false) { [weak self] _ in
            self?.hideGift(runwayInfo)
        }
    }
    
    private func createNewRunway() -> ALRunwayInfo {
        let runway = ALGiftRunwayView(config: config)
        runway.isHidden = true
        runway.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(runway)
        
        let runwayIndex = runwayInfos.count
        let topOffset = config.runwayOffsetY + CGFloat(runwayIndex) * (config.runwayHeight + config.runwaySpacing)
        
        NSLayoutConstraint.activate([
            runway.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 10),
            runway.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: topOffset),
            runway.heightAnchor.constraint(equalToConstant: config.runwayHeight),
            runway.widthAnchor.constraint(equalToConstant: 280)
        ])
        
        return ALRunwayInfo(runway: runway)
    }
    
    // 清理所有跑道和队列
    func clearAllRunways() {
        giftQueue.removeAll()
        runwayInfos.forEach { info in
            info.reset()
            info.runway.removeFromSuperview()
        }
        runwayInfos.removeAll()
    }
}

