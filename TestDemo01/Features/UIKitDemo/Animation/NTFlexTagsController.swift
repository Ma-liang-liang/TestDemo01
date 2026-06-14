//
//  NTFlexTagsController.swift
//  TestDemo01
//
//  Created by 马亮亮 on 2026/1/31.
//

import UIKit
import SnapKit

class NTFlexTagsController: SKBaseController {
    
    // MARK: - UI Components
    
    /// 左对齐的标签视图
    private lazy var leftTagsView: NTFlexTagsView = {
        let view = NTFlexTagsView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 8
        view.itemSpacing = 10
        view.lineSpacing = 10
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.alignment = .left
        return view
    }()
    
    /// 居中对齐的标签视图
    private lazy var centerTagsView: NTFlexTagsView = {
        let view = NTFlexTagsView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.itemSpacing = 12
        view.lineSpacing = 12
        view.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        view.alignment = .center
        return view
    }()
    
    /// 右对齐的标签视图
    private lazy var rightTagsView: NTFlexTagsView = {
        let view = NTFlexTagsView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.itemSpacing = 8
        view.lineSpacing = 8
        view.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        view.alignment = .right
        return view
    }()
    
    /// 左对齐标签视图的验证 Label
    private lazy var leftVerifyLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.text = "验证最后一行宽度"
        return label
    }()
    
    /// 居中对齐标签视图的验证 Label
    private lazy var centerVerifyLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        label.textColor = .systemBlue
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.text = "验证最后一行宽度"
        return label
    }()
    
    /// 右对齐标签视图的验证 Label
    private lazy var rightVerifyLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        label.textColor = .systemGreen
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.text = "验证最后一行宽度"
        return label
    }()
    
    /// 滚动视图
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    /// 内容容器
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTags()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 在布局完成后执行标签布局
        leftTagsView.performLayout()
        centerTagsView.performLayout()
        rightTagsView.performLayout()
        
        // 更新验证 Label 的位置和大小
        updateVerifyLabels()
    }
    
    /// 更新验证 Label 的位置和大小
    private func updateVerifyLabels() {
        // 左对齐验证 Label
        updateVerifyLabel(
            leftVerifyLabel,
            for: leftTagsView,
            contentInset: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        )
        
        // 居中对齐验证 Label
        updateVerifyLabel(
            centerVerifyLabel,
            for: centerTagsView,
            contentInset: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )
        
        // 右对齐验证 Label
        updateVerifyLabel(
            rightVerifyLabel,
            for: rightTagsView,
            contentInset: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )
    }
    
    /// 更新单个验证 Label
    private func updateVerifyLabel(_ label: UILabel, for tagsView: NTFlexTagsView, contentInset: UIEdgeInsets) {
        let lastLineWidth = tagsView.lastLineWidth
        let containerWidth = tagsView.bounds.width - contentInset.left - contentInset.right
        
        // 根据对齐方式计算起始 X 坐标
        var startX: CGFloat = contentInset.left
        switch tagsView.alignment {
        case .left:
            startX = contentInset.left
        case .center:
            startX = (tagsView.bounds.width - lastLineWidth) / 2
        case .right:
            startX = tagsView.bounds.width - contentInset.right - lastLineWidth
        }
        
        // 更新 Label 的 frame
        let labelY = tagsView.frame.origin.y + tagsView.contentHeight + 4
        label.frame = CGRect(
            x: tagsView.frame.origin.x + startX,
            y: labelY,
            width: lastLineWidth,
            height: 20
        )
        
        // 更新文字显示宽度值
        label.text = String(format: "最后一行宽度: %.1f", lastLineWidth)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        // 添加三个标签视图到内容容器
        contentView.addSubviews {
            leftTagsView
            centerTagsView
            rightTagsView
        }
        
        // 添加验证 Label 到 view（不是 contentView，避免影响 contentView 的高度计算）
        view.addSubview(leftVerifyLabel)
        view.addSubview(centerVerifyLabel)
        view.addSubview(rightVerifyLabel)
        
        // 左对齐标签视图约束
        leftTagsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // 居中对齐标签视图约束
        centerTagsView.snp.makeConstraints { make in
            make.top.equalTo(leftTagsView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // 右对齐标签视图约束
        rightTagsView.snp.makeConstraints { make in
            make.top.equalTo(centerTagsView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setupTags() {
        // ===== 左对齐标签视图 - 添加各种类型标签 =====
        setupLeftTags()
        
        // ===== 居中对齐标签视图 - 添加各种类型标签 =====
        setupCenterTags()
        
        // ===== 右对齐标签视图 - 添加各种类型标签 =====
        setupRightTags()
    }
    
    // MARK: - 左对齐标签
    
    private func setupLeftTags() {
        // 1. 添加 UILabel 标签
        let label1 = createLabel(text: "Swift", bgColor: .systemOrange)
        leftTagsView.addTag(label1)
        
        let label2 = createLabel(text: "iOS开发", bgColor: .systemBlue)
        leftTagsView.addTag(label2)
        
        let label3 = createLabel(text: "UIKit", bgColor: .systemPurple)
        leftTagsView.addTag(label3)
        
        // 2. 添加 UIImageView 标签
        let imageView1 = createImageView(imageName: "star.fill", tintColor: .systemYellow)
        leftTagsView.addTag(imageView1, size: CGSize(width: 40, height: 40))
        
        let label4 = createLabel(text: "SnapKit", bgColor: .systemPink)
        leftTagsView.addTag(label4)
        
        let label5 = createLabel(text: "AutoLayout", bgColor: .systemTeal)
        leftTagsView.addTag(label5)
        
        // 3. 添加自定义 UIView 标签
        let customView1 = createCustomView(color: .systemRed, text: "VIP")
        leftTagsView.addTag(customView1, size: CGSize(width: 60, height: 32))
        
        let label6 = createLabel(text: "MVC", bgColor: .systemIndigo)
        leftTagsView.addTag(label6)
        
        let label7 = createLabel(text: "MVVM", bgColor: .systemCyan)
        leftTagsView.addTag(label7)
        
        let imageView2 = createImageView(imageName: "heart.fill", tintColor: .systemRed)
        leftTagsView.addTag(imageView2, size: CGSize(width: 36, height: 36))
        
        let label8 = createLabel(text: "Combine", bgColor: .systemGreen)
        leftTagsView.addTag(label8)
        
        let label9 = createLabel(text: "RxSwift", bgColor: .systemMint)
        leftTagsView.addTag(label9)
        
        // 4. 添加更多标签测试换行
        let label10 = createLabel(text: "Objective-C", bgColor: .systemBrown)
        leftTagsView.addTag(label10)
        
        let label11 = createLabel(text: "SwiftUI", bgColor: .systemBlue)
        leftTagsView.addTag(label11)
        
        let customView2 = createCustomView(color: .systemPurple, text: "NEW")
        leftTagsView.addTag(customView2, size: CGSize(width: 60, height: 32))
    }
    
    // MARK: - 居中对齐标签
    
    private func setupCenterTags() {
        // 1. 添加 UILabel 标签
        let label1 = createLabel(text: "标签1", bgColor: .systemRed)
        centerTagsView.addTag(label1)
        
        let label2 = createLabel(text: "标签2", bgColor: .systemOrange)
        centerTagsView.addTag(label2)
        
        // 2. 添加 UIImageView 标签
        let imageView1 = createImageView(imageName: "bolt.fill", tintColor: .systemYellow)
        centerTagsView.addTag(imageView1, size: CGSize(width: 44, height: 44))
        
        let label3 = createLabel(text: "长文本标签测试", bgColor: .systemGreen)
        centerTagsView.addTag(label3)
        
        // 3. 添加自定义 UIView 标签
        let customView1 = createGradientView()
        centerTagsView.addTag(customView1, size: CGSize(width: 80, height: 36))
        
        let label4 = createLabel(text: "标签3", bgColor: .systemBlue)
        centerTagsView.addTag(label4)
        
        let label5 = createLabel(text: "标签4", bgColor: .systemPurple)
        centerTagsView.addTag(label5)
        
        let imageView2 = createImageView(imageName: "moon.fill", tintColor: .systemIndigo)
        centerTagsView.addTag(imageView2, size: CGSize(width: 40, height: 40))
        
        let label6 = createLabel(text: "居中显示", bgColor: .systemPink)
        centerTagsView.addTag(label6)
        
        let customView2 = createBadgeView(count: 99)
        centerTagsView.addTag(customView2, size: CGSize(width: 50, height: 32))
    }
    
    // MARK: - 右对齐标签
    
    private func setupRightTags() {
        // 1. 添加 UILabel 标签
        let label1 = createLabel(text: "右对齐", bgColor: .systemTeal)
        rightTagsView.addTag(label1)
        
        let label2 = createLabel(text: "标签", bgColor: .systemCyan)
        rightTagsView.addTag(label2)
        
        // 2. 添加 UIImageView 标签
        let imageView1 = createImageView(imageName: "bell.fill", tintColor: .systemOrange)
        rightTagsView.addTag(imageView1, size: CGSize(width: 38, height: 38))
        
        let label3 = createLabel(text: "测试", bgColor: .systemMint)
        rightTagsView.addTag(label3)
        
        // 3. 添加自定义 UIView 标签
        let customView1 = createIconTextView(icon: "checkmark", text: "完成")
        rightTagsView.addTag(customView1, size: CGSize(width: 80, height: 34))
        
        let label4 = createLabel(text: "Swift", bgColor: .systemOrange)
        rightTagsView.addTag(label4)
        
        let label5 = createLabel(text: "iOS", bgColor: .systemBlue)
        rightTagsView.addTag(label5)
        
        let imageView2 = createImageView(imageName: "flag.fill", tintColor: .systemRed)
        rightTagsView.addTag(imageView2, size: CGSize(width: 36, height: 36))
        
        let label6 = createLabel(text: "开发", bgColor: .systemPurple)
        rightTagsView.addTag(label6)
        
        let customView2 = createIconTextView(icon: "person.fill", text: "用户")
        rightTagsView.addTag(customView2, size: CGSize(width: 80, height: 34))
        
        let label7 = createLabel(text: "测试长文本", bgColor: .systemIndigo)
        rightTagsView.addTag(label7)
    }
    
    // MARK: - Helper Methods
    
    /// 创建 UILabel 标签
    private func createLabel(text: String, bgColor: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = bgColor
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.numberOfLines = 1
        
        // 设置内边距
        let padding = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        label.sizeToFit()
        let size = label.bounds.size
        label.frame = CGRect(x: 0, y: 0, width: size.width + padding.left + padding.right, height: size.height + padding.top + padding.bottom)
        
        return label
    }
    
    /// 创建 UIImageView 标签
    private func createImageView(imageName: String, tintColor: UIColor) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: imageName)
        imageView.tintColor = tintColor
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = tintColor.withAlphaComponent(0.1)
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        return imageView
    }
    
    /// 创建自定义 UIView 标签
    private func createCustomView(color: UIColor, text: String) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        return view
    }
    
    /// 创建渐变背景视图
    private func createGradientView() -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = true
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.systemPurple.cgColor, UIColor.systemPink.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 80, height: 36)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        let label = UILabel()
        label.text = "渐变"
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return view
    }
    
    /// 创建徽章视图
    private func createBadgeView(count: Int) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        let label = UILabel()
        label.text = "\(count)+"
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        return view
    }
    
    /// 创建图标+文本视图
    private func createIconTextView(icon: String, text: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 17
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray3.cgColor
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        
        view.addSubview(iconImageView)
        view.addSubview(label)
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }
        
        return view
    }
}
