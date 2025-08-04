//
//  StoreBoxController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/16.
//

import UIKit

class StoreBoxController: SKBaseController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupExampleViews11()
        
        // 示例1：图片在上方
        let view1 = CustomImageTextView(systemImageName: "star.fill", text: "图片在上方")
            .setImagePosition(.top)
            .setSpacing(0)
            .setContentPadding(20)
            .setImageSize(40)
            .setTextColor(.systemBlue)
            .setFont(.boldSystemFont(ofSize: 18))
        
        view1.backgroundColor = UIColor.yellow
        view1.layer.cornerRadius = 8
        
        view.addSubview(view1)
        
        view1.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
        }
    }
    
    private func setupExampleViews() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // 示例1：图片在上方
        let view1 = CustomImageTextView(systemImageName: "star.fill", text: "图片在上方")
            .setImagePosition(.top)
            .setSpacing(0)
            .setContentPadding(20)
            .setImageSize(40)
            .setTextColor(.systemBlue)
            .setFont(.boldSystemFont(ofSize: 18))
        
        view1.backgroundColor = UIColor.systemGray6
        view1.layer.cornerRadius = 8
        
        // 示例2：图片在下方
        let view2 = CustomImageTextView(systemImageName: "heart.fill", text: "图片在下方")
            .setImagePosition(.bottom)
            .setSpacing(8)
            .setContentPadding(UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
            .setImageSize(35)
            .setTextColor(.systemRed)
            .setFont(.systemFont(ofSize: 20))
        
        view2.backgroundColor = UIColor.systemPink.withAlphaComponent(0.1)
        view2.layer.cornerRadius = 8
        
        // 示例3：图片在左侧
        let view3 = CustomImageTextView(systemImageName: "leaf.fill", text: "图片在左侧\n支持多行文本")
            .setImagePosition(.left)
            .setSpacing(15)
            .setContentPadding(25)
            .setImageSize(CGSize(width: 45, height: 45))
            .setTextColor(.systemGreen)
            .setFont(.systemFont(ofSize: 16))
        
        view3.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        view3.layer.cornerRadius = 8
        
        // 示例4：图片在右侧
        let view4 = CustomImageTextView(systemImageName: "moon.fill", text: "图片在右侧")
            .setImagePosition(.right)
            .setSpacing(10)
            .setContentPadding(18)
            .setImageSize(50)
            .setTextColor(.systemPurple)
            .setFont(.italicSystemFont(ofSize: 17))
        
        view4.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        view4.layer.cornerRadius = 8
        
        // 添加到StackView
        [view1, view2, view3, view4].forEach { stackView.addArrangedSubview($0) }
        
        // 设置约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
    

    private func setupExampleViews11() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // 示例1：本地图片 + 整体点击事件
        let view1 = CustomImageTextView(systemImageName: "star.fill", text: "点击切换选中状态")
            .setImagePosition(.top)
            .setSpacing(12)
            .setContentPadding(20)
            .setImageSize(40)
            .setTextColor(.systemBlue)
            .setFont(.boldSystemFont(ofSize: 18))
            // 设置选中状态样式
            .setSelectedBackgroundColor(.systemBlue)
            .setSelectedTextColor(.white)
            .setSelectedBorderColor(.systemBlue)
            .setSelectedBorderWidth(2)
            .setSelectedCornerRadius(12)
            // 设置正常状态样式
            .setNormalBackgroundColor(.systemGray6)
            .setNormalTextColor(.systemBlue)
            .setNormalBorderColor(.clear)
            .setNormalBorderWidth(0)
            .setNormalCornerRadius(8)
            .onTap { v in
                print("整个view被点击了")
                v.toggleSelection(animated: true)
            }
            .onSelectionChanged { isSelected in
                print("1选中状态变为: \(isSelected)")
            }
        
        // 示例2：网络图片 + 高级选中效果
        let view2 = CustomImageTextView(imageURL: "https://picsum.photos/100/100", text: "高级选中效果")
            .setImagePosition(.left)
            .setSpacing(15)
            .setContentPadding(20)
            .setImageSize(60)
            .setTextColor(.systemPurple)
            .setFont(.systemFont(ofSize: 16))
            // 选中状态：放大 + 阴影效果
            .setSelectedBackgroundColor(.systemPurple.withAlphaComponent(0.2))
            .setSelectedTextColor(.systemPurple)
            .setSelectedBorderColor(.systemPurple)
            .setSelectedBorderWidth(3)
            .setSelectedCornerRadius(15)
            .setSelectedTransform(CGAffineTransform(scaleX: 1.05, y: 1.05))
            // 正常状态
            .setNormalBackgroundColor(.clear)
            .setNormalTextColor(.systemPurple)
            .setNormalCornerRadius(8)
            .setSelectionAnimationDuration(0.3)
            .onTap { v in
                v.toggleSelection()
            }
        
        // 为view2添加阴影效果
        view2.layer.shadowColor = UIColor.systemPurple.cgColor
        view2.layer.shadowOffset = CGSize(width: 0, height: 2)
        view2.layer.shadowRadius = 4
        view2.layer.shadowOpacity = 0
        
        // 示例3：多选列表项效果
        let view3 = CustomImageTextView(systemImageName: "checkmark.circle", text: "多选列表项")
            .setImagePosition(.left)
            .setSpacing(12)
            .setContentPadding(15)
            .setImageSize(24)
            // 选中状态：绿色主题
            .setSelectedBackgroundColor(.systemGreen.withAlphaComponent(0.1))
            .setSelectedTextColor(.systemGreen)
            .setSelectedBorderColor(.systemGreen)
            .setSelectedBorderWidth(1)
            // 正常状态：灰色主题
            .setNormalBackgroundColor(.systemGray6)
            .setNormalTextColor(.label)
            .setNormalBorderColor(.systemGray4)
            .setNormalBorderWidth(1)
            .setNormalCornerRadius(8)
            .setSelectedCornerRadius(8)
            .onTap { v in
                v.toggleSelection()
            }
        
        // 示例4：标签选择器效果
        let view4 = CustomImageTextView(systemImageName: "tag.fill", text: "标签选择器")
            .setImagePosition(.left)
            .setSpacing(8)
            .setContentPadding(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
            .setImageSize(16)
            .setFont(.systemFont(ofSize: 14))
            // 选中状态：胶囊形状 + 深色背景
            .setSelectedBackgroundColor(.label)
            .setSelectedTextColor(.systemBackground)
            .setSelectedCornerRadius(16)
            // 正常状态：边框样式
            .setNormalBackgroundColor(.clear)
            .setNormalTextColor(.label)
            .setNormalBorderColor(.label)
            .setNormalBorderWidth(1)
            .setNormalCornerRadius(16)
            .setSelectionAnimationDuration(0.25)
            .onTap { v in
                v.toggleSelection()
            }
        
        // 示例5：卡片选择效果
        let view5 = CustomImageTextView(imageURL: "https://picsum.photos/80/80?random=3", text: "卡片选择\n点击选择此项")
        
        view5
            .setImagePosition(.top)
            .setSpacing(10)
            .setContentPadding(16)
            .setImageSize(50)
            .setFont(.systemFont(ofSize: 14))
            // 选中状态：蓝色主题 + 阴影
            .setSelectedBackgroundColor(.systemBlue)
            .setSelectedTextColor(.white)
            .setSelectedCornerRadius(12)
            .setSelectedTransform(CGAffineTransform(translationX: 0, y: -2))
            // 正常状态
            .setNormalBackgroundColor(.systemBackground)
            .setNormalTextColor(.label)
            .setNormalBorderColor(.systemGray4)
            .setNormalBorderWidth(1)
            .setNormalCornerRadius(12)
            .onTap { v in
                v.toggleSelection()
            }
            .onSelectionChanged { isSelected in
                // 动态调整阴影
                UIView.animate(withDuration: 0.25) {
                    view5.layer.shadowOpacity = isSelected ? 0.3 : 0.1
                }
            }
        
        // 为view5添加阴影
        view5.layer.shadowColor = UIColor.black.cgColor
        view5.layer.shadowOffset = CGSize(width: 0, height: 2)
        view5.layer.shadowRadius = 8
        view5.layer.shadowOpacity = 0.1
        
        // 添加到StackView
        [view1, view2, view3, view4, view5].forEach { stackView.addArrangedSubview($0) }
        
        // 设置约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

}
