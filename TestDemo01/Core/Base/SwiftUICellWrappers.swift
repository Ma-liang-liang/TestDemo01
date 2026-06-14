import UIKit
import SwiftUI

// MARK: - Base UITableViewCell for SwiftUI
/// 一个通用的 UITableViewCell 基类，用于承载 SwiftUI 视图。
/// 适用于 iOS 13+。在 iOS 16+ 中，推荐优先使用 `contentConfiguration = UIHostingConfiguration { ... }`。
open class SwiftUIBaseTableViewCell: UITableViewCell {
    
    private var hostingController: UIHostingController<AnyView>?
    
    /// 配置 Cell 的内容
    /// - Parameters:
    ///   - view: 要显示的 SwiftUI 视图
    ///   - parentViewController: 所在的父控制器（用于正确处理生命周期事件，如 safeArea 等），通常传入 `self`
    open func setContent<Content: View>(view: Content, parentViewController: UIViewController?) {
        let anyView = AnyView(view)
        
        if let hostingController = hostingController {
            // 复用现有的 HostingController，直接更新 View
            hostingController.rootView = anyView
            hostingController.view.layoutIfNeeded()
        } else {
            // 创建新的 HostingController
            let controller = UIHostingController(rootView: anyView)
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            
            // 将 HostingController 添加为子控制器（如果有父控制器）
            if let parent = parentViewController {
                parent.addChild(controller)
                // 这一步很重要，但在 Cell 中有时会引起问题，如果是 Cell 内部管理，通常只需 addChild
                // 某些情况下不调用 didMove(toParent:) 也能工作，但标准流程是需要的。
                // 注意：在 Cell 复用时，parentViewController 应该是不变的。
                controller.didMove(toParent: parent)
            }
            
            contentView.addSubview(controller.view)
            
            // 设置约束，让 SwiftUI 视图充满 Cell
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
            
            self.hostingController = controller
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        // 这里可以根据需要清理状态，但通常更新 rootView 即可
    }
}

// MARK: - Base UICollectionViewCell for SwiftUI
/// 一个通用的 UICollectionViewCell 基类，用于承载 SwiftUI 视图。
/// 适用于 iOS 13+。在 iOS 16+ 中，推荐优先使用 `contentConfiguration = UIHostingConfiguration { ... }`。
open class SwiftUIBaseCollectionViewCell: UICollectionViewCell {
    
    private var hostingController: UIHostingController<AnyView>?
    
    /// 配置 Cell 的内容
    /// - Parameters:
    ///   - view: 要显示的 SwiftUI 视图
    ///   - parentViewController: 所在的父控制器
    open func setContent<Content: View>(view: Content, parentViewController: UIViewController?) {
        let anyView = AnyView(view)
        
        if let hostingController = hostingController {
            hostingController.rootView = anyView
            hostingController.view.layoutIfNeeded()
        } else {
            let controller = UIHostingController(rootView: anyView)
            controller.view.backgroundColor = .clear
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            
            if let parent = parentViewController {
                parent.addChild(controller)
                controller.didMove(toParent: parent)
            }
            
            contentView.addSubview(controller.view)
            
            NSLayoutConstraint.activate([
                controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
            
            self.hostingController = controller
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
    }
}

