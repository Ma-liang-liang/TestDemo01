//
//  Define.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/14.
//

import UIKit

typealias SKVoidBlock = (() -> Void)


/// 获取当前活动窗口的顶层控制器
func getCurrentViewController() -> UIViewController? {
    // 使用 getKewWindow 方法获取关键窗口
    guard let keyWindow = UIScreen.getKeyWindow(), let rootViewController = keyWindow.rootViewController else {
        return nil
    }
    
    // 辅助函数：递归地找到最上层的视图控制器
    func findTopViewController(from viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController,
           let visibleController = navigationController.visibleViewController {
            return findTopViewController(from: visibleController)
        } else if let tabBarController = viewController as? UITabBarController,
                  let selectedController = tabBarController.selectedViewController {
            return findTopViewController(from: selectedController)
        } else if let presentedController = viewController?.presentedViewController {
            return findTopViewController(from: presentedController)
        } else {
            return viewController
        }
    }
    // 从根视图控制器开始查找最上层的视图控制器
    return findTopViewController(from: rootViewController)
}

func measureTime(name: String, block: () -> Void) {
    let startTime = DispatchTime.now()
    block() // 执行函数
    let endTime = DispatchTime.now()
    let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let timeInterval = TimeInterval(nanoTime) / 1_000_000_000 // 转换为秒
    print("\(name) 消耗时间 --- \(timeInterval)")
}
