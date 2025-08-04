//
//  UIScreen+Extension.swift
//  sufinc_tool_module
//
//  Created by sunshine on 2023/6/1.
//

import UIKit

public
extension UIScreen {
    
    static var kScreenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    static var kScreenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    static var kNavBarHeight: CGFloat {
        return 44 + statusBarHeight
    }
    
    static var kTabbarHeight: CGFloat {
        return 49 + safeAreaBottomHeight
    }
    
    static var scaleSize: CGFloat {
        return min(kScreenWidth, kScreenHeight) / 375.0
    }
    
    static var safeAreaHeight: CGFloat {
        if #available(iOS 11.0, *) {
            guard let safeInsets = getKeyWindow()?.safeAreaInsets else {
                return 0
            }
            return kScreenHeight - safeInsets.top - safeInsets.bottom
        }
        return kScreenHeight
    }
    
    /// 获取状态栏高度（兼容 iOS 15+）
    static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用 windowScene 获取状态栏高度
            let windowScene = UIApplication.shared.connectedScenes
                .first { $0.activationState == .foregroundActive ||
                    $0.activationState == .foregroundInactive } as? UIWindowScene
            return windowScene?.statusBarManager?.statusBarFrame.height ?? 44
        } else {
            // iOS 12 及以下版本直接获取状态栏高度
            return UIApplication.shared.statusBarFrame.height
        }
    }
    
    static var safeAreaBottomHeight: CGFloat {
        if #available(iOS 11.0, *) {
            guard let safeInsets = getKeyWindow()?.safeAreaInsets else {
                return 0
            }
            return safeInsets.bottom
        }
        return 0
    }
    
    static var safeAreaTopHeight: CGFloat {
        if #available(iOS 11.0, *) {
            guard let safeInsets = getKeyWindow()?.safeAreaInsets else {
                return 0
            }
            return safeInsets.top
        }
        
        return 0
    }
    
    static var safeArea: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            
            guard let safeInsets = getKeyWindow()?.safeAreaInsets else {
                return UIEdgeInsets.zero
            }
            return safeInsets
        }
        return UIEdgeInsets.zero
    }
    
    static func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
            return window
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    /// 获取 App 中所有窗口（兼容 iOS 13 前后）
    static var allWindows: [UIWindow] {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
        } else {
            return UIApplication.shared.windows
        }
    }
}

