//
//  CGNavigationManager.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/5.
//
import SwiftUI
import UIKit

// MARK: - 导航栈标识符
enum CGStackIdentifier: String, CaseIterable {
    case main = "mainStack"
    case explore = "exploreStack"
    case profile = "profileStack"
}

// MARK: - 运行时关联 Key
private struct AssociatedKeys {
    // 使用一个静态变量的地址作为唯一的 key，保证安全
    static var swiftUIViewTypeNameKey: UInt8 = 0
    
    static var stackIdKey: UInt8 = 1 // 新增

}

// MARK: - UIViewController 扩展，用于关联 SwiftUI 视图类型名称
extension UIViewController {
    
    /// 一个计算属性，用于通过 Objective-C 运行时来存储和读取关联的 SwiftUI 视图类型名称。
    /// - 这使得我们可以在不知道具体 SwiftUI 视图类型的情况下，识别 UIViewController 是由哪个 View 创建的。
    var swiftUIViewTypeName: String? {
        get {
            // 获取关联对象
            return objc_getAssociatedObject(self, &AssociatedKeys.swiftUIViewTypeNameKey) as? String
        }
        set {
            // 设置关联对象
            // 使用 RETAIN_NONATOMIC 策略，因为我们正在存储一个对象（String）
            objc_setAssociatedObject(self, &AssociatedKeys.swiftUIViewTypeNameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UINavigationController {
    var stackId: CGStackIdentifier? {
        get {
            guard let rawValue = objc_getAssociatedObject(self, &AssociatedKeys.stackIdKey) as? String else { return nil }
            return CGStackIdentifier(rawValue: rawValue)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.stackIdKey, newValue?.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


// MARK: - 多栈导航管理器
class CGNavigationManager: ObservableObject {
    // 单例
    static let shared = CGNavigationManager()
    
    // 存储多个导航栈
    private var navigationStacks: [CGStackIdentifier: UINavigationController] = [:]
    
    // 当前活跃的栈标识
    @Published var currentStackId: CGStackIdentifier = .main
    
    private init() {}
    
    // MARK: - 栈管理
    /// 获取或创建导航栈
    func getOrCreateStack(id: CGStackIdentifier) -> UINavigationController? {
        if let existingStack = navigationStacks[id] {
            return existingStack
        }
        return nil
    }
    
    /// 设置导航栈
    func setNavigationStack(_ navigationController: UINavigationController, forId id: CGStackIdentifier) {
        navigationStacks[id] = navigationController
    }
    
    /// 切换当前活跃栈
    func switchToStack(id: CGStackIdentifier) {
        if navigationStacks[id] != nil {
            currentStackId = id
        }
    }
    
    /// 移除导航栈
    func removeStack(id: CGStackIdentifier) {
        navigationStacks.removeValue(forKey: id)
    }
    
    /// 获取当前活跃栈
    private var currentStack: UINavigationController? {
        return navigationStacks[currentStackId]
    }
    
    // MARK: - 导航操作
    /// 推入新页面
    func push<Content: View>(_ view: Content, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId.rawValue)")
            return
        }
        
        let hostingController = UIHostingController(rootView: view)
        
        // 【优化】使用封装好的计算属性来设置类型名称
        hostingController.swiftUIViewTypeName = String(describing: Content.self)
        
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: animated)
    }
    
    func push(_ viewController: UIViewController, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId.rawValue)")
            return
        }
        
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    /// 弹出当前页面
    func pop(animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        navigationController.popViewController(animated: animated)
    }
    
    /// 弹出到根页面
    func popToRoot(animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        navigationController.popToRootViewController(animated: animated)
    }
    
    /// 弹出到指定 SwiftUI 页面类型
    func popTo<T: View>(pageType: T.Type, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId.rawValue)")
            return
        }
        
        let targetTypeName = String(describing: pageType)
        
        // 从后往前遍历寻找目标 VC
        for vc in navigationController.viewControllers.reversed() {
            // 【优化】直接通过计算属性读取并比较，代码更清晰
            if vc.swiftUIViewTypeName == targetTypeName {
                navigationController.popToViewController(vc, animated: animated)
                return // 找到后立即返回
            }
        }
        
        print("Could not find a page of type \(targetTypeName) in the navigation stack.")
    }
    
    func popTo<T: UIViewController>(pageType: T.Type, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else {
            print("Navigation stack not found for id: \(targetStackId.rawValue)")
            return
        }
        
        let targetTypeName = String(describing: pageType)
        // 从后往前遍历寻找目标 VC
        for vc in navigationController.viewControllers.reversed() {
            if vc.isMember(of: pageType) {
                navigationController.popToViewController(vc, animated: animated)
                return // 找到后立即返回
            }
        }
        
        print("Could not find a page of type \(targetTypeName) in the navigation stack.")
    }
    
    /// 替换当前页面
    func replace<Content: View>(_ view: Content, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        let hostingController = UIHostingController(rootView: view)
        
        // 【优化】同样使用计算属性
        hostingController.swiftUIViewTypeName = String(describing: Content.self)
        
        hostingController.hidesBottomBarWhenPushed = true
        
        var viewControllers = navigationController.viewControllers
        if !viewControllers.isEmpty {
            viewControllers[viewControllers.count - 1] = hostingController
            navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    func replace(_ viewController: UIViewController, animated: Bool = true, stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        viewController.hidesBottomBarWhenPushed = true
        
        var viewControllers = navigationController.viewControllers
        if !viewControllers.isEmpty {
            viewControllers[viewControllers.count - 1] = viewController
            navigationController.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    // ... (canPop, getStackCount, clearStack 等方法保持不变) ...
    func canPop(stackId: CGStackIdentifier? = nil) -> Bool {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return false }
        return navigationController.viewControllers.count > 1
    }
    
    func getStackCount(stackId: CGStackIdentifier? = nil) -> Int {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return 0 }
        return navigationController.viewControllers.count
    }
    
    func clearStack(stackId: CGStackIdentifier? = nil) {
        let targetStackId = stackId ?? currentStackId
        guard let navigationController = navigationStacks[targetStackId] else { return }
        
        if let rootViewController = navigationController.viewControllers.first {
            navigationController.setViewControllers([rootViewController], animated: false)
        }
    }
}

// MARK: - 导航容器视图
struct CGNavigationContainer<Content: View>: View {
    let content: Content
    let stackId: CGStackIdentifier
    
    init(stackId: CGStackIdentifier = .main, @ViewBuilder content: () -> Content) {
        self.stackId = stackId
        self.content = content()
    }
    
    var body: some View {
        CGNavigationControllerWrapper(rootView: content, stackId: stackId)
            .ignoresSafeArea()
    }
}

// MARK: - UINavigationController 包装器
struct CGNavigationControllerWrapper<RootView: View>: UIViewControllerRepresentable {
    let rootView: RootView
    let stackId: CGStackIdentifier
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let hostingController = UIHostingController(rootView: rootView)
        
        // 【核心】根视图控制器也需要关联类型名称
        let typeName = String(describing: RootView.self)
        objc_setAssociatedObject(hostingController, &AssociatedKeys.swiftUIViewTypeNameKey, typeName, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        let navigationController = UINavigationController(rootViewController: hostingController)
        
        navigationController.setNavigationBarHidden(true, animated: false)
        
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
        
        CGNavigationManager.shared.setNavigationStack(navigationController, forId: stackId)
        
        // 只有当 manager 里还没有活跃栈时，才切换到当前创建的栈
        if CGNavigationManager.shared.getOrCreateStack(id: CGNavigationManager.shared.currentStackId) == nil {
            CGNavigationManager.shared.switchToStack(id: stackId)
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(stackId: stackId)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let stackId: CGStackIdentifier
        
        init(stackId: CGStackIdentifier) {
            self.stackId = stackId
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return CGNavigationManager.shared.canPop(stackId: stackId)
        }
    }
}

// MARK: - 导航栏配置
struct CGNavigationBarConfig {
    let title: String
    let showBackButton: Bool
    let backgroundColor: Color
    let titleColor: Color
    let backButtonColor: Color
    let rightBarItems: [CGNavigationBarItem]
    let leftBarItems: [CGNavigationBarItem]
    let height: CGFloat
    let showSeparator: Bool
    let backButtonText: String
    let titleFont: Font
    let customBackAction: (() -> Void)?
    
    init(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        titleColor: Color = .primary,
        backButtonColor: Color = .blue,
        rightBarItems: [CGNavigationBarItem] = [],
        leftBarItems: [CGNavigationBarItem] = [],
        height: CGFloat = 44,
        showSeparator: Bool = true,
        backButtonText: String = "",
        titleFont: Font = .headline,
        customBackAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.backButtonColor = backButtonColor
        self.rightBarItems = rightBarItems
        self.leftBarItems = leftBarItems
        self.height = height
        self.showSeparator = showSeparator
        self.backButtonText = backButtonText
        self.titleFont = titleFont
        self.customBackAction = customBackAction
    }
}

// MARK: - 导航栏按钮项
struct CGNavigationBarItem: Identifiable {
    let id = UUID()
    let icon: String?
    let text: String?
    let color: Color
    let action: () -> Void
    
    init(icon: String, color: Color = .blue, action: @escaping () -> Void) {
        self.icon = icon
        self.text = nil
        self.color = color
        self.action = action
    }
    
    init(text: String, color: Color = .blue, action: @escaping () -> Void) {
        self.icon = nil
        self.text = text
        self.color = color
        self.action = action
    }
}

// MARK: - SwiftUI 导航栏 (可复用组件)
struct CGCustomNavigationBar: View {
    let config: CGNavigationBarConfig
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    leftItems()
                    
                    Spacer()
                    
                    rightItems()
                }
                titleView()
            }
            .padding(.horizontal, 16)
            .frame(height: config.height)
            .background(config.backgroundColor)
            
            if config.showSeparator {
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator))
            }
        }
    }
    
    
    private func titleView() -> some View {
        Text(config.title)
            .font(config.titleFont)
            .fontWeight(.semibold)
            .foregroundColor(config.titleColor)
            .lineLimit(1)
    }
    
    private func leftItems() -> some View {
        // 左侧区域
        HStack(spacing: 8) {
            if config.showBackButton && navigationManager.canPop() {
                Button(action: {
                    if let customAction = config.customBackAction {
                        customAction()
                    } else {
                        navigationManager.pop()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .medium))
                        Text(config.backButtonText)
                            .font(.system(size: 17))
                    }
                    .foregroundColor(config.backButtonColor)
                }
            }
            
            ForEach(config.leftBarItems) { item in
                Button(action: item.action) {
                    if let icon = item.icon {
                        Image(systemName: icon).font(.system(size: 18))
                    } else if let text = item.text {
                        Text(text).font(.system(size: 17))
                    }
                }
                .foregroundColor(item.color)
            }
        }
    }
    
    private func rightItems() -> some View {
        HStack(spacing: 8) {
            ForEach(config.rightBarItems) { item in
                Button(action: item.action) {
                    if let icon = item.icon {
                        Image(systemName: icon).font(.system(size: 18))
                    } else if let text = item.text {
                        Text(text).font(.system(size: 17))
                    }
                }
                .foregroundColor(item.color)
            }
        }
        .frame(minWidth: 60, alignment: .trailing)
    }
    
    
}

// MARK: - 导航栏修饰符
struct CGNavigationBarModifier: ViewModifier {
    let config: CGNavigationBarConfig
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            CGCustomNavigationBar(config: config)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - 便捷扩展
extension View {
    /// 添加自定义导航栏 (完整配置)
    func navigationBar(config: CGNavigationBarConfig) -> some View {
        self.modifier(CGNavigationBarModifier(config: config))
    }
    
    /// 添加自定义导航栏 (简化配置)
    func navigationBar(
        title: String = "",
        showBackButton: Bool = true,
        backgroundColor: Color = Color(.systemBackground),
        rightBarItems: [CGNavigationBarItem] = [],
        leftBarItems: [CGNavigationBarItem] = [],
        customBackAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(CGNavigationBarModifier(
            config: CGNavigationBarConfig(
                title: title,
                showBackButton: showBackButton,
                backgroundColor: backgroundColor,
                rightBarItems: rightBarItems,
                leftBarItems: leftBarItems,
                customBackAction: customBackAction
            )
        ))
    }
}
