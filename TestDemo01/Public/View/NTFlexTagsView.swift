//
//  NTFlexTagsView.swift
//  TestDemo01
//
//  Created by 马亮亮 on 2026/1/31.
//

import UIKit
import SnapKit

/// 标签布局对齐方式
enum NTFlexTagsAlignment {
    case left      // 左对齐
    case center    // 居中对齐
    case right     // 右对齐
}

/// 灵活的标签容器视图
class NTFlexTagsView: UIView {
    
    // MARK: - 公开属性
    
    /// 标签之间的水平间距（列间距）
    var itemSpacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 行之间的垂直间距（行间距）
    var lineSpacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 内容内边距
    var contentInset: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 布局对齐方式
    var alignment: NTFlexTagsAlignment = .left {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 获取布局后的最终高度
    private(set) var contentHeight: CGFloat = 0
    
    /// 获取最后一行标签所占据的宽度
    private(set) var lastLineWidth: CGFloat = 0
    
    /// 获取所有标签视图
    var tagViews: [UIView] {
        return tagsContainer.subviews
    }
    
    // MARK: - 私有属性
    
    /// 标签容器视图
    private lazy var tagsContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    /// 存储标签尺寸的配置
    private var tagSizeConfigs: [UIView: CGSize] = [:]
    
    /// 高度约束，用于动态更新
    private var flexHeightConstraint: Constraint?
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - 私有方法
    
    private func setupUI() {
        addSubview(tagsContainer)
        tagsContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(contentInset)
        }
    }
    
    // MARK: - 公开方法
    
    /// 添加标签视图
    /// - Parameter tagView: 要添加的标签视图（可以是 UILabel、UIView、UIImageView 等）
    func addTag(_ tagView: UIView) {
        tagsContainer.addSubview(tagView)
        // 默认使用标签的固有尺寸
        tagSizeConfigs[tagView] = nil
    }
    
    /// 添加标签视图并设置固定大小
    /// - Parameters:
    ///   - tagView: 要添加的标签视图
    ///   - size: 标签的固定大小
    func addTag(_ tagView: UIView, size: CGSize) {
        tagsContainer.addSubview(tagView)
        tagSizeConfigs[tagView] = size
    }
    
    /// 设置指定标签的大小
    /// - Parameters:
    ///   - tagView: 目标标签视图
    ///   - size: 标签大小
    func setSize(_ size: CGSize, for tagView: UIView) {
        guard tagView.superview == tagsContainer else { return }
        tagSizeConfigs[tagView] = size
    }
    
    /// 移除指定标签
    /// - Parameter tagView: 要移除的标签视图
    func removeTag(_ tagView: UIView) {
        tagView.removeFromSuperview()
        tagSizeConfigs.removeValue(forKey: tagView)
    }
    
    /// 移除所有标签
    func removeAllTags() {
        tagsContainer.subviews.forEach { $0.removeFromSuperview() }
        tagSizeConfigs.removeAll()
    }
    
    /// 执行布局，计算并设置所有标签的位置
    /// 调用此方法后，容器会自动调整高度，最后一行恰好位于容器底部
    func performLayout() {
        layoutTags()
    }
    
    /// 获取布局后的最终高度
    /// - Returns: 布局完成后的内容高度
    func getContentHeight() -> CGFloat {
        return contentHeight
    }
    
    // MARK: - 布局计算
    
    private func layoutTags() {
        let containerWidth = bounds.width - contentInset.left - contentInset.right
        guard containerWidth > 0 else { return }
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        var lineViews: [[UIView]] = [[]]
        var lineWidths: [CGFloat] = [0]
        
        // 第一遍：计算每行包含哪些视图
        for tagView in tagsContainer.subviews {
            let tagSize = getSize(for: tagView)
            
            // 检查是否需要换行
            if currentX > 0 && currentX + tagSize.width > containerWidth {
                // 换行
                lineWidths.append(currentX - itemSpacing) // 减去最后一个标签的间距
                lineViews.append([])
                currentX = 0
                currentY += currentLineHeight + lineSpacing
                currentLineHeight = 0
            }
            
            // 添加到当前行
            lineViews[lineViews.count - 1].append(tagView)
            currentX += tagSize.width + itemSpacing
            currentLineHeight = max(currentLineHeight, tagSize.height)
            
            // 更新当前行宽度
            if lineViews.count == lineWidths.count {
                lineWidths[lineWidths.count - 1] = currentX - itemSpacing
            }
        }
        
        // 更新最后一行的宽度
        if currentX > 0 {
            lineWidths[lineWidths.count - 1] = currentX - itemSpacing
        }
        
        // 第二遍：根据对齐方式设置每个标签的位置
        currentY = 0
        for (lineIndex, line) in lineViews.enumerated() {
            guard !line.isEmpty else { continue }
            
            let lineWidth = lineWidths[lineIndex]
            var lineHeight: CGFloat = 0
            
            // 计算行高
            for tagView in line {
                let tagSize = getSize(for: tagView)
                lineHeight = max(lineHeight, tagSize.height)
            }
            
            // 根据对齐方式计算起始X坐标
            var startX: CGFloat = 0
            switch alignment {
            case .left:
                startX = 0
            case .center:
                startX = (containerWidth - lineWidth) / 2
            case .right:
                startX = containerWidth - lineWidth
            }
            
            // 布局当前行的标签
            currentX = startX
            for tagView in line {
                let tagSize = getSize(for: tagView)
                
                // 垂直居中对齐
                let tagY = currentY + (lineHeight - tagSize.height) / 2
                
                tagView.snp.remakeConstraints { make in
                    make.leading.equalToSuperview().offset(currentX)
                    make.top.equalToSuperview().offset(tagY)
                    make.width.equalTo(tagSize.width)
                    make.height.equalTo(tagSize.height)
                }
                
                currentX += tagSize.width + itemSpacing
            }
            
            currentY += lineHeight + lineSpacing
        }
        
        // 计算最终高度（减去最后一行的行间距）
        contentHeight = currentY > 0 ? currentY - lineSpacing + contentInset.top + contentInset.bottom : contentInset.top + contentInset.bottom
        
        // 记录最后一行标签所占据的宽度
        lastLineWidth = lineWidths.last ?? 0
        
        // 更新高度约束
        flexHeightConstraint?.deactivate()
        snp.makeConstraints { make in
            flexHeightConstraint = make.height.equalTo(contentHeight).constraint
        }
        
        // 强制布局更新
        layoutIfNeeded()
    }
    
    /// 获取标签的尺寸
    private func getSize(for tagView: UIView) -> CGSize {
        // 如果设置了固定大小，使用固定大小
        if let fixedSize = tagSizeConfigs[tagView], fixedSize.width > 0 && fixedSize.height > 0 {
            return fixedSize
        }
        
        // 否则使用视图的固有大小
        let fittingSize = tagView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if fittingSize.width > 0 && fittingSize.height > 0 {
            return fittingSize
        }
        
        // 如果都无法获取，使用视图当前的 bounds
        return tagView.bounds.size
    }
    
}
