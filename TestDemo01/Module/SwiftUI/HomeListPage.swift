//
//  HomeListPage.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/17.
//

import SwiftUI

struct HomeListPage: View {
    
    let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        NavigationView {
            VStack {
                //                ALNavBarView {
                //                    dismiss.callAsFunction()
                //                }
                
                List(items, id: \.self) { item in
                    NavigationLink {
//                        ALDetailItemPage(title: item)
                        CGKitContentView()
                            .navigationBarHidden(true)
                    } label: {
                        Text(item)
                            .foregroundStyle(Color.pink)
                            .fontWeight(.medium)
                            .font(.system(size: 18))
                    }
                }
                .listStyle(.plain)
                
                
            }
            .interactiveDismissDisabled(false)
            //            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    ZStack {
                        HStack {
                            Spacer()
                            Text("Home List")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.pink)
                            Spacer()
                        }
                        .frame(width: UIScreen.kScreenWidth, height: 44)
                        HStack {
                            Spacer()
                                .frame(width: 16)
                            Image(systemName: "xmark")
                                .resizable()
                                .foregroundStyle(Color.black)
                                .frame(width: 20, height: 20)
                                .aspectRatio(contentMode: .fit)
                                .onTapGesture {
                                    dismiss.callAsFunction()
                                }
                            Spacer()
                        }
                    }
                    
                }
            }
            
        }
        .navigationBarHidden(true)
       
    }
}

#Preview {
    HomeListPage()
}

// MARK: - 导航栏配置模型
struct NavigationBarConfig {
    var title: TitleContent = .text("")
    var leftItems: [BarItem] = []
    var rightItems: [BarItem] = []
    var backgroundColor: Color = .clear
    var hidesBackButton: Bool = false
    var titleColor: Color = .primary
    var barTintColor: Color = .primary
    
    enum TitleContent {
        case text(String)
        case view(AnyView)
    }
    
    struct BarItem {
        let content: Content
        let action: (() -> Void)?
        
        enum Content {
            case text(String)
            case icon(String)
            case view(AnyView)
        }
        
        // 快速创建方法
        static func text(_ text: String, action: (() -> Void)? = nil) -> BarItem {
            BarItem(content: .text(text), action: action)
        }
        
        static func icon(_ systemName: String, action: (() -> Void)? = nil) -> BarItem {
            BarItem(content: .icon(systemName), action: action)
        }
        
        static func view<Content: View>(_ view: Content, action: (() -> Void)? = nil) -> BarItem {
            BarItem(content: .view(AnyView(view)), action: action)
        }
    }
}

// MARK: - View 扩展
extension View {
    /// 自定义导航栏配置
    func customNavigationBar(_ config: NavigationBarConfig) -> some View {
        self
            .navigationBarBackButtonHidden(config.hidesBackButton)
            .toolbar {
                // 标题
                ToolbarItem(placement: .principal) {
                    switch config.title {
                    case .text(let title):
                        Text(title)
                            .foregroundColor(config.titleColor)
                            .font(.headline)
                    case .view(let view):
                        view
                    }
                }
                
                // 左侧按钮
                if !config.leftItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 12) {
                            ForEach(config.leftItems.indices, id: \.self) { index in
                                barItemView(item: config.leftItems[index])
                            }
                        }
                    }
                }
                
                // 右侧按钮
                if !config.rightItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            ForEach(config.rightItems.indices, id: \.self) { index in
                                barItemView(item: config.rightItems[index])
                            }
                        }
                    }
                }
            }
            .toolbarBackground(config.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // 生成按钮视图
    @ViewBuilder
    private func barItemView(item: NavigationBarConfig.BarItem) -> some View {
        switch item.content {
        case .text(let text):
            Button(action: { item.action?() }) {
                Text(text)
                    .foregroundColor(.primary)
            }
        case .icon(let systemName):
            Button(action: { item.action?() }) {
                Image(systemName: systemName)
                    .foregroundColor(.primary)
            }
        case .view(let view):
            Button(action: { item.action?() }) {
                view
            }
        }
    }
}


