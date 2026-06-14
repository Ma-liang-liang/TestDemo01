//
//  UIView++.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/6.
//

import UIKit

@resultBuilder
public struct SubviewBuilder {
    
    public static func buildBlock(_ subviews: UIView...) -> [UIView] {
        subviews
    }
    
    public static func buildEither(first component: [UIView]) -> [UIView] {
        component
    }
    
    public static func buildEither(second component: [UIView]) -> [UIView] {
        component
    }
    
    public static func buildArray(_ components: [[UIView]]) -> [UIView] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [UIView]?) -> [UIView] {
        component ?? []
    }
   
}

public extension UIView {
    
    func addSubviews(@SubviewBuilder _ builder: () -> [UIView]) {
        builder().forEach { addSubview($0) }
    }
}

extension UIView {
    
    func setShadow(size: CGSize, color: UIColor, radius: CGFloat, opacity: Float = 0.6) {
        layer.shadowOffset = size
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
    }
    
    func addRectCorner(corner: UIRectCorner, radius: CGFloat) {
        
        var corners: CACornerMask = []
        if corner.contains(.topLeft) {
            corners.insert(.layerMinXMinYCorner)
        }
        if corner.contains(.topRight) {
            corners.insert(.layerMaxXMinYCorner)
        }
        if corner.contains(.bottomLeft) {
            corners.insert(.layerMinXMaxYCorner)
        }
        if corner.contains(.bottomRight) {
            corners.insert(.layerMaxXMaxYCorner)
        }
        if corner.contains(.bottomRight) {
            corners.insert(.layerMaxXMaxYCorner)
        }
        if corner.contains(.allCorners) {
            corners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                       .layerMinXMaxYCorner,.layerMaxXMaxYCorner]
        }
        layer.maskedCorners = corners
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}

// MARK: - 点击事件闭包扩展（无内存泄漏风险）
extension UIView {
    private struct AssociatedKeys {
        static var tapGestureKey: UInt8 = 0
        static var tapHandlerKey: UInt8 = 0
    }
    
    /// 添加点击事件（无动画）
    func addTapAction(_ handler: @escaping () -> Void) {
        isUserInteractionEnabled = true
        
        // 创建手势识别器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.cancelsTouchesInView = false
        
        // 存储闭包（使用weak-strong dance避免循环引用）
        let wrapper = ClosureWrapper(handler: handler)
        objc_setAssociatedObject(self, &AssociatedKeys.tapHandlerKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 存储手势（用于后续移除）
        objc_setAssociatedObject(self, &AssociatedKeys.tapGestureKey, tapGesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        addGestureRecognizer(tapGesture)
    }
    
    /// 处理点击事件
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        // 安全获取闭包
        if let wrapper = objc_getAssociatedObject(self, &AssociatedKeys.tapHandlerKey) as? ClosureWrapper {
            wrapper.handler()
        }
    }
    
    /// 移除点击事件（可选）
    func removeTapAction() {
        if let gesture = objc_getAssociatedObject(self, &AssociatedKeys.tapGestureKey) as? UIGestureRecognizer {
            removeGestureRecognizer(gesture)
        }
        objc_setAssociatedObject(self, &AssociatedKeys.tapGestureKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.tapHandlerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// 闭包包装器（解决内存泄漏问题）
    private class ClosureWrapper {
        let handler: () -> Void
        init(handler: @escaping () -> Void) {
            self.handler = handler
        }
    }
}
