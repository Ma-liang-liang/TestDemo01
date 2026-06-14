//
//  UILbabelExtension.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/25.
//

import UIKit

extension UILabel {
    
    func setIcon(_ unicode: String, size: CGFloat, color: UIColor,
                 alignment: NSTextAlignment = .center,
                 drawsAsynchronously: Bool = true) {
        layer.drawsAsynchronously = true  // 异步绘制
        font = UIFont(name: "iconfont", size: size)
        text = unicode
        textColor = color
        textAlignment = alignment
    }
}
