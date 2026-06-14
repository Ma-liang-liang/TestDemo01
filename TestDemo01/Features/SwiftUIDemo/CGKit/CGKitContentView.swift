//
//  testCommon.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/29.
//
import SwiftUI
import UIKit
// MARK: - 示例页面
struct CGHomePage: View {
    @State private var showAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("欢迎来到首页")
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    CGNavigationCard(title: "用户中心", icon: "person.circle", color: .blue) {
                        CGNavigationManager.shared.push(CGUserCenterPage())
                    }
                    CGNavigationCard(title: "商品列表", icon: "bag", color: .green) {
                        CGNavigationManager.shared.push(CGProductListPage())
                    }
                    CGNavigationCard(title: "多栈测试", icon: "square.stack.3d.up", color: .purple) {
                        CGNavigationManager.shared.push(CGMultiStackTestPage())
                    }
                    CGNavigationCard(title: "无导航栏页面", icon: "eye.slash", color: .gray) {
                        CGNavigationManager.shared.push(CGNoNavBarPage())
                    }
                    CGNavigationCard(title: "自定义布局导航栏", icon: "wand.and.stars", color: .yellow) {
                        CGNavigationManager.shared.push(CGCustomLayoutPage())
                    }
                    CGNavigationCard(title: "设置", icon: "gearshape", color: .orange) {
                        CGNavigationManager.shared.push(CGSettingsPage())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBar(
            title: "首页",
            showBackButton: false,
            rightBarItems: [
                CGNavigationBarItem(icon: "bell", color: .red) {
                    CGNavigationManager.shared.push(CGNotificationPage())
                },
                CGNavigationBarItem(icon: "magnifyingglass") {
                    showAlert = true
                }
            ]
        )
        .alert("搜索", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text("搜索功能正在开发中...")
        }
    }
}

// MARK: - 其他页面实现 (Page后缀)

// MARK: 多栈测试
struct CGMultiStackTestPage: View {
    @StateObject private var navigationManager = CGNavigationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("多栈导航测试").font(.title2).fontWeight(.bold)
            Text("当前栈ID: \(navigationManager.currentStackId.rawValue)").font(.caption).foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Button("切换到 'explore' 栈") {
                    CGNavigationManager.shared.push(Text("在'explore'栈的页面"), stackId: .explore)
                }.buttonStyle(CGButtonStyle(color: .purple))
                
                Button("无动画跳转") {
                    navigationManager.push(CGTestAnimationPage(), animated: false)
                }.buttonStyle(CGButtonStyle(color: .green))
                
                Button("替换当前页面") {
                    navigationManager.replace(CGReplacementPage(), animated: true)
                }.buttonStyle(CGButtonStyle(color: .orange))
                
                Button("清空栈(保留根页面)") {
                    navigationManager.clearStack()
                }.buttonStyle(CGButtonStyle(color: .red))
            }
            
            Spacer()
        }
        .padding()
        .navigationBar(title: "多栈测试")
    }
}

// MARK: 无导航栏页面示例
struct CGNoNavBarPage: View {
    var body: some View {
        ZStack {
            Color.mint.ignoresSafeArea()
            VStack {
                Text("这是一个没有使用\n`.navigationBar` 修饰符的页面")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: { CGNavigationManager.shared.pop() }) {
                    Text("手动返回").padding().background(.white).foregroundColor(.black).cornerRadius(10)
                }
            }
        }
    }
}

// MARK: 自定义布局导航栏示例
struct CGCustomLayoutPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("这是一个广告Banner").frame(maxWidth: .infinity).padding().background(Color.yellow)
            CGCustomNavigationBar(
                config: .init(
                    title: "自定义布局",
                    backgroundColor: .mint,
                    rightBarItems: [.init(icon: "star.fill", action: {})]
                )
            )
            List {
                Text("内容1")
                    .onTapGesture {
                        let vc = SecondController()
                        CGNavigationManager.shared.push(vc)
                    }
                Text("内容2")
                    .onTapGesture {
                        let vc = SecondController()
                        CGNavigationManager.shared.replace(vc)
                    }
                
                Text("内容3 - web")
                    .onTapGesture {
                        let vc = WebViewController(url: "https://www.baidu.com/")
                        CGNavigationManager.shared.push(vc)
                    }
                
                Text("内容4 - present")
                    .onTapGesture {
                        let vc = UIHostingController(rootView: CGSettingsPage())
                        vc.modalPresentationStyle = .formSheet
                        getCurrentViewController()?.present(vc, animated: true)
                    }
                
                Text("内容4 - input")
                    .onTapGesture {
                        CGNavigationManager.shared.push(InputPage())
                    }
                
            }
        }
    }
}

struct CGTestAnimationPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("无动画跳转测试").font(.title2)
            Button("返回(有动画)") {
                CGNavigationManager.shared.pop(animated: true)
            }.buttonStyle(CGButtonStyle(color: .blue))
            Button("返回(无动画)") {
                CGNavigationManager.shared.pop(animated: false)
            }.buttonStyle(CGButtonStyle(color: .red))
        }
        .navigationBar(title: "动画测试")
    }
}

struct CGReplacementPage: View {
    var body: some View {
        VStack {
            Text("页面已被替换").font(.title2)
            Text("这个页面替换了之前的页面").foregroundColor(.secondary)
        }
        .navigationBar(title: "替换页面")
    }
}

struct CGUserCenterPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill").font(.system(size: 80)).foregroundColor(.blue)
                    Text("张三").font(.title2).fontWeight(.semibold)
                    Text("ID: 123456789").font(.caption).foregroundColor(.secondary)
                }.padding(.vertical, 20)
                
                VStack(spacing: 0) {
                    CGUserCenterRow(icon: "person", title: "个人信息") { CGNavigationManager.shared.push(CGProfilePage()) }
                    CGUserCenterRow(icon: "heart", title: "我的收藏") { CGNavigationManager.shared.push(CGFavoritePage()) }
                    CGUserCenterRow(icon: "clock", title: "浏览历史") { CGNavigationManager.shared.push(CGHistoryPage()) }
                }
                .background(Color(.systemBackground)).cornerRadius(12)
            }.padding()
        }
        .navigationBar(
            title: "用户中心",
            backgroundColor: .pink.opacity(0.6),
            rightBarItems: [CGNavigationBarItem(icon: "gearshape") { CGNavigationManager.shared.push(CGSettingsPage()) }]
        )
        .background(Color(.systemGroupedBackground))
    }
}

struct CGProductListPage: View {
    let products = (1...20).map { "商品 \($0)" }
    var body: some View {
        List(products, id: \.self) { product in
            Button(product) {
                CGNavigationManager.shared.push(CGProductDetailPage(productName: product))
            }
            .foregroundColor(.primary)
        }
        .navigationBar(
            title: "商品列表",
            rightBarItems: [CGNavigationBarItem(icon: "line.3.horizontal.decrease.circle") {}]
        )
    }
}

struct CGProductDetailPage: View {
    let productName: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 200).cornerRadius(8)
                VStack(alignment: .leading, spacing: 8) {
                    Text(productName).font(.title2).fontWeight(.bold)
                    Text("￥199.00").font(.title3).foregroundColor(.red)
                }
                VStack(spacing: 12) {
                    Button("再 Push 一个商品列表页") {
                        CGNavigationManager.shared.push(CGProductListPage())
                    }.buttonStyle(CGButtonStyle(color: .purple))
                    
                    Button("返回到上一个商品列表页 (popTo pageType)") {
                        CGNavigationManager.shared.popTo(pageType: CGProductListPage.self)
                    }.buttonStyle(CGButtonStyle(color: .blue))
                    
                    Button("返回首页 (popToRoot)") {
                        CGNavigationManager.shared.popToRoot()
                    }.buttonStyle(CGButtonStyle(color: .green))
                }
                .padding(.top, 30)
                Spacer()
            }.padding()
        }
        .navigationBar(title: productName)
    }
}

struct CGSettingsPage: View {
    
    @State private var showSheet = false
    
    var body: some View {
        VStack {
            List {
                Section("账户") { Text("修改密码"); Text("隐私设置") }
                Section("通用") { Text("推送通知"); Text("清除缓存") }
            }
            
            Spacer()
            
            Button("清空栈(保留根页面)") {
                showSheet.toggle()
            }
            .buttonStyle(CGButtonStyle(color: .red))
            .padding(.horizontal, 16)
            
            Spacer(minLength: UIScreen.safeAreaBottomHeight + 16)
        }
        .navigationBar(title: "设置")
        .sheet(isPresented: $showSheet) {
            VStack {
                Text("License Agreement")
                    .font(.title)
                    .padding(50)
                Text("Terms and conditions go here.")
                    .padding(50)
                Button("Dismiss",
                       action: {
                    showSheet.toggle()
                })
            }
        }
    }
}

struct CGProfilePage: View {
    var body: some View {
        Form {
            Section("基本信息") { HStack { Text("姓名"); Spacer(); Text("张三").foregroundColor(.secondary) } }
        }
        .navigationBar(title: "个人信息")
    }
}

struct CGFavoritePage: View {
    var body: some View {
        Text("我的收藏").frame(maxWidth: .infinity, maxHeight: .infinity).navigationBar(title: "我的收藏")
    }
}

struct CGHistoryPage: View {
    var body: some View {
        Text("浏览历史").frame(maxWidth: .infinity, maxHeight: .infinity).navigationBar(title: "浏览历史")
    }
}

struct CGNotificationPage: View {
    var body: some View {
        Text("通知中心").frame(maxWidth: .infinity, maxHeight: .infinity).navigationBar(title: "通知")
    }
}

// MARK: - 辅助视图
struct CGNavigationCard: View {
    let title: String, icon: String, color: Color, action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 32)).foregroundColor(color)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CGUserCenterRow: View {
    let icon: String, title: String, action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.blue).frame(width: 24)
                Text(title).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CGButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white).padding().frame(maxWidth: .infinity)
            .background(color).cornerRadius(8).scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 应用入口
struct CGKitContentView: View {
    var body: some View {
        CGNavigationContainer(stackId: .main) {
            CGHomePage()
        }
    }
}

#Preview {
    CGKitContentView()
}
