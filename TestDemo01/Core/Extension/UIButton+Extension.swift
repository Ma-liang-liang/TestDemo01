//
//  UIButton+Extension.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/29.
//

import UIKit


extension UIButton {
    
    /// 设置按钮的内容内边距，兼容 iOS 15 及以上版本
    /// - Parameters:
    ///   - top: 上边距
    ///   - left: 左边距
    ///   - bottom: 下边距
    ///   - right: 右边距
    func setContentEdgeInsets(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        if #available(iOS 15.0, *) {
            // iOS 15 及以上版本使用 `configuration`
            var configuration = self.configuration ?? UIButton.Configuration.plain()
            configuration.baseBackgroundColor = .clear
            configuration.background.backgroundColor = .clear
            configuration.contentInsets = NSDirectionalEdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
            self.configuration = configuration
        } else {
            // iOS 15 以下版本直接设置 `contentEdgeInsets`
            self.contentEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        }
    }
    
    func setAllTitleColor(titleColor: UIColor?) {
        
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor, for: .selected)
        setTitleColor(titleColor, for: .highlighted)
        setTitleColor(titleColor, for: .disabled)
        setTitleColor(titleColor, for: .focused)
    }
    
    func setAllTitle(title: String) {
        
        setTitle(title, for: .normal)
        setTitle(title, for: .selected)
        setTitle(title, for: .highlighted)
        setTitle(title, for: .disabled)
        setTitle(title, for: .focused)
    }
    
    
    func setAllImage(image: UIImage?) {
        
        setImage(image, for: .normal)
        setImage(image, for: .selected)
        setImage(image, for: .highlighted)
        setImage(image, for: .disabled)
        setImage(image, for: .focused)
    }
    
    func setAllBacgroudImage(image: UIImage?) {
        
        setBackgroundImage(image, for: .normal)
        setBackgroundImage(image, for: .selected)
        setBackgroundImage(image, for: .highlighted)
        setBackgroundImage(image, for: .disabled)
        setBackgroundImage(image, for: .focused)
    }
    
}

