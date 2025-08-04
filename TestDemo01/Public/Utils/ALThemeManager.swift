//
//  SKThemeManager.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/8.
//

import Foundation
import UIKit

// 主题模式枚举
enum ALThemeMode: String {
    case light
    case dark
    case system
}

extension Notification.Name {
    
    static let themeChangeNotiName = Notification.Name("themeChangeNotiName")
}

// 主题管理类
class ALThemeManager: NSObject {
  
    static let shared = ALThemeManager()
    
    private let appThemeKey = "k_app_theme_key"
    
    private let systemThemeKey = "k_system_theme_key"
    
    private let standardUserDefault = UserDefaults.standard
    
    override init() {
        super.init()
        // 监听系统主题变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeDidChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 当前系统主题
    var currentSystemTheme: UIUserInterfaceStyle {
        return UITraitCollection.current.userInterfaceStyle
    }
    // 上次保存的系统主题样式
    var lastSaveSystemTheme: UIUserInterfaceStyle {
        let value = standardUserDefault.integer(forKey: systemThemeKey)
        return UIUserInterfaceStyle(rawValue: value) ?? .unspecified
    }
    
    // 上次保存的系统主题样式
    var lastSavedAppTheme: ALThemeMode {
        let value = standardUserDefault.string(forKey: appThemeKey) ?? ""
        return ALThemeMode(rawValue: value) ?? .dark
    }
    
    // 设置app主题
    func setAppTheme(_ mode: ALThemeMode) {
        if lastSavedAppTheme == mode {
            let style = mode == .dark ? UIUserInterfaceStyle.dark : UIUserInterfaceStyle.light
            updateAllWindowUserInterfaceStyle(style: style)
            return
        }
       
        standardUserDefault.set(mode.rawValue, forKey: appThemeKey)
        standardUserDefault.synchronize()
        
        if mode == .system {
            updateAllWindowUserInterfaceStyle(style: currentSystemTheme)
            saveSystemThemeStyle(style: currentSystemTheme)
        } else {
            let style = mode == .dark ? UIUserInterfaceStyle.dark : UIUserInterfaceStyle.light
            updateAllWindowUserInterfaceStyle(style: style)
        }
        notifyThemeChange()
    }
    
    func saveSystemThemeStyle(style: UIUserInterfaceStyle) {
        standardUserDefault.setValue(style.rawValue, forUndefinedKey: systemThemeKey)
        standardUserDefault.synchronize()
    }
    
    func updateAllWindowUserInterfaceStyle(style: UIUserInterfaceStyle) {
        for window in UIScreen.allWindows {
            window.overrideUserInterfaceStyle = style
        }
    }
    
    // 系统主题变化处理
    @objc private func systemThemeDidChange() {
        if lastSavedAppTheme != .system {
            return
        }
        if lastSaveSystemTheme == currentSystemTheme {
            return
        }
        updateAllWindowUserInterfaceStyle(style: currentSystemTheme)
        saveSystemThemeStyle(style: currentSystemTheme)
        notifyThemeChange()
    }
    
    // 通知主题变化
    private func notifyThemeChange() {
        NotificationCenter.default.post(Notification(name: .themeChangeNotiName))
    }
}

// 扩展UIColor以支持动态颜色
extension UIColor {
    static func dynamicColor(light: UIColor?, dark: UIColor?) -> UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark ?? .black
            default:
                return light ?? .white
            }
        }
    }
}

extension UIImage {
    /// 动态图片（自动适配 Light/Dark 模式）
    static func dynamicImage(light: UIImage?, dark: UIImage?) -> UIImage {
        guard let light, let dark else {
            return UIImage()
        }
        let imageAsset = UIImageAsset()
        
        // 为 Light 模式注册图片
        let lightTraits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .light)
        ])
        imageAsset.register(light, with: lightTraits)
        
        // 为 Dark 模式注册图片
        let darkTraits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .dark)
        ])
        imageAsset.register(dark, with: darkTraits)
        
        return imageAsset.image(with: UITraitCollection.current)
    }
}
