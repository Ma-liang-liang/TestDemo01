//
//  ALApp.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/5.
//

import SwiftUI

// MARK: - =================== UIKit TabBarController Wrapper (核心) ===================
struct MainTabBarControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        
        // 为每个 Tab 创建并配置导航栈
        let mainStack = createNavStack(
            for: ALHomePage(),
            stackId: .main,
            title: "主页",
            imageName: "house.fill"
        )
        
        let exploreStack = createNavStack(
            for: ALSearchPage(),
            stackId: .explore,
            title: "搜索",
            imageName: "magnifyingglass"
        )
        
        let profileStack = createNavStack(
            for: ALProfilePage(),
            stackId: .profile,
            title: "我的",
            imageName: "person.fill",
            badgeValue: "New" // 演示角标
        )
        
        // 将所有导航栈设置给 TabBarController
        tabBarController.viewControllers = [mainStack, exploreStack, profileStack]
        
        // 监听 Tab 切换事件
        tabBarController.delegate = context.coordinator
        
        return tabBarController
    }
    
    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        // 通常不需要在这里做什么
    }
    
    // 创建 Coordinator 来处理代理回调
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // Coordinator 负责处理 UITabBarControllerDelegate 的方法
    class Coordinator: NSObject, UITabBarControllerDelegate {
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            // 当用户切换 Tab 时，我们需要更新 CGNavigationManager 的状态
            guard let nav = viewController as? UINavigationController,
                  let stackId = nav.stackId else { return }
            
            CGNavigationManager.shared.switchToStack(id: stackId)
        }
    }
    
    /// 一个辅助方法，用于为每个 Tab 创建一个配置好的 UINavigationController
    private func createNavStack<RootView: View>(
        for rootView: RootView,
        stackId: CGStackIdentifier,
        title: String,
        imageName: String,
        badgeValue: String? = nil
    ) -> UINavigationController {
        
        let hostingController = UIHostingController(rootView: rootView.navigationBarHidden(true))
        hostingController.swiftUIViewTypeName = String(describing: RootView.self)
        
        let navController = UINavigationController(rootViewController: hostingController)
        // 关键：隐藏 UIKit 的导航栏，因为我们使用自己的 SwiftUI 导航栏
        navController.navigationBar.isHidden = true
        
        // 设置 TabBarItem
        navController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: nil // 可以提供一个不同的选中图标
        )
        
        // 设置角标
        navController.tabBarItem.badgeValue = badgeValue
        
        // 关联 stackId 到 UINavigationController 上，方便后面识别
        navController.stackId = stackId
        
        // 将创建的导航栈注册到我们的管理器中
        CGNavigationManager.shared.setNavigationStack(navController, forId: stackId)
        
        return navController
    }
}


// MARK: - =================== Core UI (TabView) ===================
struct ALMainTabView: View {
    // 实例化导航管理器，作为全局状态
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    // 使用 Enum 作为 Tag 和 State，可读性高且类型安全
    enum TabIdentifier: String {
        case home
        case search
        case profile
    }
    
    @State private var selectedTab: TabIdentifier = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // 主页 Tab
            CGNavigationContainer(stackId: .main, content: {
                ALHomePage()
            })
                .tabItem { Label("主页", systemImage: "house.fill") }
                .tag(TabIdentifier.home)
                .ignoresSafeArea(.all, edges: .top) // 让内容延伸到顶部安全区

            // 搜索 Tab
            CGNavigationContainer(stackId: .explore, content: {
                ALSearchPage()
            })
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(TabIdentifier.search)
                .ignoresSafeArea(.all, edges: .top)

            // 个人中心 Tab
            CGNavigationContainer(stackId: .profile, content: {
                ALProfilePage()
            })
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(TabIdentifier.profile)
                .badge("New") // 演示角标
                .ignoresSafeArea(.all, edges: .top)
        }
        .tint(.accentColor) // 设置选中项的颜色
        .onChange(of: selectedTab) { newTab in
            // 当用户手动切换 Tab 时，通知 NavigationManager 当前活跃的栈已改变
            switch newTab {
            case .home:
                navigationManager.switchToStack(id: .main)
            case .search:
                navigationManager.switchToStack(id: .explore)
            case .profile:
                navigationManager.switchToStack(id: .profile)
            }
        }
    }
}


// MARK: - =================== Demo Pages (AL Prefix) ===================

// MARK: --- 主页流程 ---
struct ALHomePage: View {
    var body: some View {
        VStack(spacing: 0) {
            CGCustomNavigationBar(config: .init(title: "主页", showBackButton: false))
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("这是主页内容").padding()
                    Button("Push to Detail Page") {
                        // 使用导航管理器推入新页面
                        CGNavigationManager.shared.push(ALHomeDetailPage(itemNumber: 1))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ALHomeDetailPage: View {
    let itemNumber: Int
    
    var body: some View {
        VStack(spacing: 0) {
            CGCustomNavigationBar(config: .init(title: "详情页 \(itemNumber)", backButtonText: "返回"))
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("这是详情页 \(itemNumber) 的内容").padding()
                    Button("Push to Another Detail") {
                        CGNavigationManager.shared.push(ALHomeDetailPage(itemNumber: itemNumber + 1))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: --- 搜索流程 ---
struct ALSearchPage: View {
    var body: some View {
        VStack(spacing: 0) {
            CGCustomNavigationBar(config: .init(title: "搜索", showBackButton: false))
            Spacer()
            Text("这是搜索页面")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: --- 个人中心流程 ---
struct ALProfilePage: View {
    var body: some View {
        VStack(spacing: 0) {
            
            CGCustomNavigationBar(config: CGNavigationBarConfig(
                title: "我的",
                showBackButton: false,
                rightBarItems: [
                    .init(icon: "gearshape.fill", action: {
                        CGNavigationManager.shared.push(ALProfileSettingsPage(), stackId: .profile)
                    })]
            ))
            
            ScrollView {
                VStack {
                    Text("这是个人中心页面").padding()
                    Button("跳转到设置") {
                        CGNavigationManager.shared.push(ALProfileSettingsPage(), stackId: .profile)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ALProfileSettingsPage: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack {
                    Text("这是设置页面").padding()
                    Button("返回个人中心首页 (PopToRoot)") {
                        // 演示返回到当前栈的根视图
                        CGNavigationManager.shared.popToRoot(stackId: .profile)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationBar(config: CGNavigationBarConfig(
            title: "设置",
            backButtonText: "我的"
        ))
    }
}

