//
//  TabScrollViewController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/11.
//

import UIKit

class TabScrollViewController: SKBaseController {
    
    // 顶部标签栏
    private let tabView = UIView()
    private let tabStackView = UIStackView()
    private let indicatorView = UIView()
    
    // 内容滚动视图
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 标签数据
    private let tabs = ["首页", "推荐", "热门", "最新", "关注"]
    private var tabButtons: [UIButton] = []
    
    // 字体设置
    private let selectedFont = UIFont.systemFont(ofSize: 16, weight: .bold)
    private let normalFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    private let selectedColor: UIColor = .black
    private let normalColor: UIColor = .gray
    
    // 当前选中索引
    private var currentIndex = 0 {
        didSet {
            // 只有在真正变化时才更新
            if oldValue != currentIndex {
                updateTabButtonsAppearance()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 确保视图布局完成后更新指示器位置
        if tabButtons.count > 0 && indicatorView.frame == .zero {
            view.layoutIfNeeded()
            updateIndicatorPosition(animated: false)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupTabView()
        setupScrollView()
    }
    
    private func setupTabView() {
        tabView.backgroundColor = .white
        view.addSubview(tabView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 设置 StackView
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.alignment = .center
        tabView.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(equalTo: tabView.topAnchor),
            tabStackView.bottomAnchor.constraint(equalTo: tabView.bottomAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: tabView.trailingAnchor)
        ])
        
        // 添加标签按钮
        for (index, title) in tabs.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(index == 0 ? selectedColor : normalColor, for: .normal)
            button.titleLabel?.font = index == 0 ? selectedFont : normalFont
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            tabStackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        // 设置指示器
        indicatorView.backgroundColor = .green
        tabView.addSubview(indicatorView)
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: tabView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 内容视图
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // 添加页面视图
        var previousView: UIView?
        for (index, title) in tabs.enumerated() {
            let pageView = UIView()
            pageView.backgroundColor = UIColor(
                red: CGFloat.random(in: 0.7...1),
                green: CGFloat.random(in: 0.7...1),
                blue: CGFloat.random(in: 0.7...1),
                alpha: 1
            )
            
            let label = UILabel()
            label.text = "这是 \(title) 页面"
            label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            label.textColor = .white
            pageView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: pageView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: pageView.centerYAnchor)
            ])
            
            contentView.addSubview(pageView)
            pageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])
            
            if let previousView = previousView {
                pageView.leadingAnchor.constraint(equalTo: previousView.trailingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            }
            
            previousView = pageView
        }
        
        if let lastView = previousView {
            contentView.trailingAnchor.constraint(equalTo: lastView.trailingAnchor).isActive = true
        }
    }
    
    // 更新指示器位置
    private func updateIndicatorPosition(animated: Bool = true) {
        guard currentIndex < tabButtons.count else { return }
        
        let selectedButton = tabButtons[currentIndex]
        let indicatorWidth: CGFloat = 30
        
        let centerX = selectedButton.center.x - indicatorWidth / 2
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.indicatorView.frame = CGRect(
                    x: centerX,
                    y: self.tabView.frame.height - 3,
                    width: indicatorWidth,
                    height: 3
                )
            }
        } else {
            indicatorView.frame = CGRect(
                x: centerX,
                y: tabView.frame.height - 3,
                width: indicatorWidth,
                height: 3
            )
        }
    }
    
    // 更新标签按钮外观
    private func updateTabButtonsAppearance() {
        tabButtons.forEach { button in
            let isSelected = button.tag == currentIndex
            button.setTitleColor(isSelected ? selectedColor : normalColor, for: .normal)
            button.titleLabel?.font = isSelected ? selectedFont : normalFont
        }
    }
    
    // 标签按钮点击事件
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != currentIndex else { return }
        
        currentIndex = index
        updateIndicatorPosition()
        
        // 滚动到对应页面
        let offsetX = CGFloat(index) * scrollView.bounds.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    
    // 根据滚动位置更新标签和指示器
    private func updateTabForScrollOffset(_ offsetX: CGFloat) {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        
        let progress = offsetX / pageWidth
        let currentPage = Int(progress)
        let nextPage = currentPage + 1
        
        // 边界检查
        guard nextPage < tabButtons.count else { return }
        
        // 计算过渡进度 (0.0 ~ 1.0)
        let transitionProgress = progress - CGFloat(currentPage)
        
        // 获取当前和下一个按钮
        let currentButton = tabButtons[currentPage]
        let nextButton = tabButtons[nextPage]
        
        // 更新颜色过渡
        let currentColor = selectedColor.interpolate(to: normalColor, progress: transitionProgress)
        let nextColor = normalColor.interpolate(to: selectedColor, progress: transitionProgress)
        
        currentButton.setTitleColor(currentColor, for: .normal)
        nextButton.setTitleColor(nextColor, for: .normal)
        
        // 更新字体大小过渡
        let currentFontSize = 16 - (2 * transitionProgress)
        let nextFontSize = 14 + (2 * transitionProgress)
        
        currentButton.titleLabel?.font = UIFont.systemFont(
            ofSize: currentFontSize,
            weight: transitionProgress > 0.5 ? .medium : .bold
        )
        nextButton.titleLabel?.font = UIFont.systemFont(
            ofSize: nextFontSize,
            weight: transitionProgress > 0.5 ? .bold : .medium
        )
        
        // 更新指示器位置
        let currentCenter = currentButton.center.x
        let nextCenter = nextButton.center.x
        let indicatorWidth: CGFloat = 30
        let indicatorCenterX = currentCenter + (nextCenter - currentCenter) * transitionProgress
        
        indicatorView.frame = CGRect(
            x: indicatorCenterX - indicatorWidth / 2,
            y: tabView.frame.height - 3,
            width: indicatorWidth,
            height: 3
        )
        
        // 只有当滑动超过50%时才更新当前索引
        if transitionProgress > 0.5 {
            currentIndex = nextPage
        } else {
            currentIndex = currentPage
        }
    }
}

// MARK: - UIScrollViewDelegate
extension TabScrollViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        updateTabForScrollOffset(scrollView.contentOffset.x)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        let pageWidth = scrollView.bounds.width
        currentIndex = Int(round(scrollView.contentOffset.x / pageWidth))
        updateIndicatorPosition()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        updateIndicatorPosition()
    }
}

// UIColor 扩展，实现颜色插值
extension UIColor {
    func interpolate(to color: UIColor, progress: CGFloat) -> UIColor {
        let progress = max(0, min(1, progress))
        
        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        self.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        
        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        color.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let red = fromRed + (toRed - fromRed) * progress
        let green = fromGreen + (toGreen - fromGreen) * progress
        let blue = fromBlue + (toBlue - fromBlue) * progress
        let alpha = fromAlpha + (toAlpha - fromAlpha) * progress
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
