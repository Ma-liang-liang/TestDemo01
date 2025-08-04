//
//  MarqueeLabel.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/22.
//

import UIKit

class MarqueeLabel: UIView {
    
    // MARK: - 公共属性
    
    /// 富文本内容 (Source of Truth)
    /// 如果设置此属性，`text`, `textColor`, 和 `font` 属性将被忽略。
    var attributedText: NSAttributedString? {
        didSet {
            updateContent()
        }
    }
    
    /// 文字内容 (便捷属性)
    /// 会使用当前的 `font` 和 `textColor` 创建一个富文本。
    var text: String? {
        get {
            return attributedText?.string
        }
        set {
            guard let newText = newValue else {
                attributedText = nil
                return
            }
            // 使用当前样式创建富文本
            let attributes: [NSAttributedString.Key: Any] = [
                .font: self.font,
                .foregroundColor: self.textColor
            ]
            self.attributedText = NSAttributedString(string: newText, attributes: attributes)
        }
    }
    
    /// 文字颜色
    /// 注意：此属性仅在通过 `text` 属性设置纯文本时生效。
    /// 如果已经设置了 `attributedText`，更改此属性会重新生成富文本。
    var textColor: UIColor = .label {
        didSet {
            // 仅当内容是从纯文本创建时才更新属性
            updateTextAttributes()
        }
    }
    
    /// 字体
    /// 注意：此属性仅在通过 `text` 属性设置纯文本时生效。
    /// 如果已经设置了 `attributedText`，更改此属性会重新生成富文本。
    var font: UIFont = .systemFont(ofSize: 17) {
        didSet {
            // 仅当内容是从纯文本创建时才更新属性
            updateTextAttributes()
        }
    }
    
    var scrollDuration: Double = 5.0 {
        didSet { restartAnimationIfNeeded() }
    }
    
    var spacing: CGFloat = 40 {
        didSet {
            setNeedsLayout()
            restartAnimationIfNeeded()
        }
    }
    
    var repeatCount: Int = 0 { // 0 表示无限次
        didSet { restartAnimationIfNeeded() }
    }
    
    enum Direction {
        case left, right
    }
    var direction: Direction = .left {
        didSet { restartAnimationIfNeeded() }
    }
    
    // MARK: - 内部属性
    
    private lazy var leadingLabel: UILabel = createLabel()
    private lazy var trailingLabel: UILabel = createLabel()
    
    private var animationTimer: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var pausedProgress: CGFloat = 0
    private var currentRepeatCount = 0
    private var isAnimationActive = false
    private var contentSize: CGSize = .zero
    
    // MARK: - 初始化与生命周期
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        clipsToBounds = true
        addSubview(leadingLabel)
        addSubview(trailingLabel)
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopAnimationTimer()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            stopAnimation()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if needsScrolling() {
            updateAnimatedLayout()
        } else {
            updateStaticLayout()
        }
    }
    
    // MARK: - Auto Layout 支持
    
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
    
    // MARK: - 动画控制 (无变化)
    
    func startAnimation() {
        guard !isAnimationActive else { return }
        isAnimationActive = true
        guard needsScrolling() else { return }
        resetAnimationState()
        startAnimationTimer()
    }
    
    func stopAnimation() {
        isAnimationActive = false
        stopAnimationTimer()
        resetAnimationState()
        setNeedsLayout()
    }
    
    func pauseAnimation() {
        guard isAnimationActive else { return }
        isAnimationActive = false
        if let timer = animationTimer {
            let elapsed = CACurrentMediaTime() - animationStartTime
            pausedProgress += CGFloat(elapsed / scrollDuration)
            timer.invalidate()
            self.animationTimer = nil
        }
    }
    
    func resumeAnimation() {
        guard !isAnimationActive, needsScrolling() else { return }
        isAnimationActive = true
        startAnimationTimer()
    }
    
    // MARK: - 私有方法
    
    private func createLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        return label
    }
    
    private func needsScrolling() -> Bool {
        return contentSize.width > bounds.width
    }
    
    /// **核心更新**: 这是所有内容更新的入口点
    private func updateContent() {
        // 将富文本应用到两个标签
        leadingLabel.attributedText = attributedText
        trailingLabel.attributedText = attributedText
        
        // **核心更新**: 使用 attributedText 计算尺寸
        // 使用 boundingRect 获取更精确的尺寸，但对于单行UILabel，.size()通常足够且更快
        contentSize = attributedText?.size() ?? .zero
        
        // 更新 Auto Layout 系统并触发布局
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        
        // 如果动画正在运行，可能需要根据新的文本长度重启
        restartAnimationIfNeeded()
    }
    
    /// **新增**: 当 font 或 textColor 改变时，重新生成 attributedText
    private func updateTextAttributes() {
        // 仅在 attributedText 有内容时才操作
        guard let currentText = self.attributedText?.string, !currentText.isEmpty else { return }
        
        // 创建新的富文本，这将触发 attributedText 的 didSet，然后调用 updateContent()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: self.font,
            .foregroundColor: self.textColor
        ]
        self.attributedText = NSAttributedString(string: currentText, attributes: attributes)
    }

    // 布局方法现在依赖于 `contentSize`，因此无需修改
    private func updateStaticLayout() {
        trailingLabel.isHidden = true
        leadingLabel.frame = CGRect(
            x: (bounds.width - contentSize.width) / 2,
            y: (bounds.height - contentSize.height) / 2,
            width: contentSize.width,
            height: contentSize.height
        )
    }

    private func updateAnimatedLayout() {
        trailingLabel.isHidden = false
        
        let scrollDistance = contentSize.width + spacing
        let totalProgress = CGFloat(currentRepeatCount) + pausedProgress
        
        var currentOffset = totalProgress * scrollDistance
        currentOffset.formTruncatingRemainder(dividingBy: scrollDistance)

        let yPos = (bounds.height - contentSize.height) / 2
        
        if direction == .left {
            leadingLabel.frame = CGRect(x: -currentOffset, y: yPos, width: contentSize.width, height: contentSize.height)
            trailingLabel.frame = CGRect(x: -currentOffset + scrollDistance, y: yPos, width: contentSize.width, height: contentSize.height)
        } else {
            leadingLabel.frame = CGRect(x: currentOffset - scrollDistance, y: yPos, width: contentSize.width, height: contentSize.height)
            trailingLabel.frame = CGRect(x: currentOffset, y: yPos, width: contentSize.width, height: contentSize.height)
        }
    }
    
    // 动画逻辑和状态管理方法无需修改
    private func resetAnimationState() {
        currentRepeatCount = 0
        pausedProgress = 0
        animationStartTime = 0
    }
    
    private func startAnimationTimer() {
        guard animationTimer == nil, isAnimationActive, needsScrolling() else { return }
        animationStartTime = CACurrentMediaTime()
        animationTimer = CADisplayLink(target: self, selector: #selector(updateAnimation))
        animationTimer?.add(to: .main, forMode: .common)
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func restartAnimationIfNeeded() {
        guard isAnimationActive else { return }
        stopAnimationTimer()
        if !needsScrolling() {
            setNeedsLayout()
            return
        }
        resetAnimationState()
        startAnimationTimer()
    }
    
    @objc private func updateAnimation() {
        guard isAnimationActive else { return }
        
        let elapsed = CACurrentMediaTime() - animationStartTime
        var progress = CGFloat(elapsed / scrollDuration)
        
        if progress >= 1.0 {
            let cyclesCompleted = floor(progress)
            currentRepeatCount += Int(cyclesCompleted)
            
            if repeatCount > 0 && currentRepeatCount >= repeatCount {
                stopAnimation()
                return
            }
            
            progress -= cyclesCompleted
            animationStartTime = CACurrentMediaTime()
        }
        
        pausedProgress = progress
        setNeedsLayout()
    }
    
    // MARK: - 应用状态通知处理 (无变化)
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func handleAppWillResignActive() {
        if isAnimationActive {
            pauseAnimation()
            isAnimationActive = true
        }
    }
    
    @objc private func handleAppDidBecomeActive() {
        if isAnimationActive {
            isAnimationActive = false
            resumeAnimation()
        }
    }
}
