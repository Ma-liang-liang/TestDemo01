//
//  SFSymbol.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/25.
//

import UIKit
/// 系统图标
enum SystemIcon: String {
    
    /// ios 13
    case arrowLeft = "chevron.left"
    
    case arrowRight = "chevron.right"
    
    case arrowUp = "chevron.up"
    
    case arrowDown = "chevron.down"
    /// 顺时针刷新标识
    case refresh_clock_wise = "arrow.clockwise"
    
    /// X关闭标识
    case close_xmark = "xmark"
    
    ///问题标识
    case question_mark_circle = "questionmark.circle"
    
    ///感叹标识
    case exclamation_mark_circle = "exclamationmark.circle"
    
    /// +标识
    case plus_mark = "plus"
    
    /// 勾选标识
    case check_mark = "checkmark"

    
    // 常用图标（按功能分类）
    case home = "house"
    case search = "magnifyingglass"
    case settings = "gear"
    case heart = "heart.fill"
    case share = "square.and.arrow.up"
    case trash = "trash"
    case profile = "person.crop.circle"
        
}

extension SystemIcon {
    /// 生成配置好的 UIImage
    func image(
        size: CGFloat = 24,
        weight: UIImage.SymbolWeight = .regular,
        scale: UIImage.SymbolScale = .default,
        color: UIColor? = .black,
        configuration: UIImage.Configuration? = nil
    ) -> UIImage? {
        // 基础配置
        var config = UIImage.SymbolConfiguration(
            pointSize: size,
            weight: weight,
            scale: scale
        )
        
        // 合并外部传入的配置（优先级更高）
        if let externalConfig = configuration {
            config = config.applying(externalConfig)
        }
        
        // 生成图像
        let image = UIImage(
            systemName: self.rawValue,
            withConfiguration: config
        )
        
        // 着色处理
        if let color = color {
            return image?.withTintColor(
                color,
                renderingMode: .alwaysOriginal
            )
        }
        
        return image
    }
    
    /// 快速生成模板图像（适合按钮使用）
    func templateImage(size: CGFloat = 24) -> UIImage? {
        UIImage(
            systemName: rawValue,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: size)
        )?
            .withRenderingMode(.alwaysTemplate)
    }
}

extension SystemIcon {
    /// 支持多色图标（iOS 15+）
    @available(iOS 15.0, *)
    func multicolorImage(
        paletteColors: [UIColor],
        size: CGFloat = 24
    ) -> UIImage? {
        let config = UIImage.SymbolConfiguration(
            paletteColors: paletteColors
        ).applying(
            UIImage.SymbolConfiguration(pointSize: size)
        )
        
        return UIImage(
            systemName: rawValue,
            withConfiguration: config
        )
    }
    
    /// 支持可变值动画（iOS 16+）
    @available(iOS 16.0, *)
    func variableImage(
        value: Double,
        size: CGFloat = 24
    ) -> UIImage? {
        let config = UIImage.SymbolConfiguration(
            pointSize: value
        ).applying(
            UIImage.SymbolConfiguration(pointSize: size)
        )
        
        return UIImage(
            systemName: rawValue,
            withConfiguration: config
        )
    }
    
    static func getIcon(icon: SystemIcon,
                   size: CGFloat = 24,
                   weight: UIImage.SymbolWeight = .regular,
                   scale: UIImage.SymbolScale = .default,
                   color: UIColor? = .black,
                   configuration: UIImage.Configuration? = nil) -> UIImage? {
        
        return icon.image(size: size, weight: weight, scale: scale,
                   color: color, configuration: configuration)
    }
}

extension UIImage {
    
    static func systemIconImage(
        systemIcon: SystemIcon,
        size: CGFloat = 24,
        weight: UIImage.SymbolWeight = .regular,
        scale: UIImage.SymbolScale = .default,
        color: UIColor? = .black,
        configuration: UIImage.Configuration? = nil
    ) -> UIImage? {
        systemIcon.image(size: size, weight: weight, scale: scale, color: color, configuration: configuration)
    }
}
