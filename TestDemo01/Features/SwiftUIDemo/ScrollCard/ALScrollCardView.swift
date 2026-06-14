//
//  ALScrollCardView.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/8.
//

import SwiftUI

struct ALScrollCardView: View {
    @State private var selectedMethod = 0
    
    var body: some View {
        TabView {
            // 方法1：TabView + PageTabViewStyle
            TabViewPagingExample()
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("TabView")
                }
            
            // 方法2：ScrollView + ScrollViewReader
            ScrollViewPagingExample()
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("ScrollView")
                }
            
            // 方法3：LazyVStack + ScrollViewReader (垂直滑动)
            LazyVStackPagingExample()
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("LazyVStack")
                }
        }
    }
}

// MARK: - 方法1：TabView + PageTabViewStyle (最简单)
struct TabViewPagingExample: View {
    var body: some View {
        // 模拟数据
        let cardData = Array(0..<100).map { index in
            CardData(
                id: index,
                title: "卡片 \(index + 1)",
                subtitle: "这是第 \(index + 1) 张卡片",
                color: [.blue, .purple, .green, .orange, .red, .pink][index % 6]
            )
        }
        
        ALTabViewPaging(
            items: cardData,
            showTopInfo: true,
            showPageIndicator: true,
            onPageChanged: { index in
                print("页面切换到: \(index)")
            },
            onNearEnd: { index in
                print("即将到达末尾，可以加载更多数据")
            }
        ) { card in
            CardView(card: card)
        }
    }
}

// MARK: - 可复用的TabView分页组件
struct ALTabViewPaging<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let showTopInfo: Bool
    let showPageIndicator: Bool
    let onPageChanged: ((Int) -> Void)?
    let onNearEnd: ((Int) -> Void)?
    let content: (Item) -> Content
    
    @State private var currentIndex = 0
    
    init(
        items: [Item],
        showTopInfo: Bool = false,
        showPageIndicator: Bool = true,
        onPageChanged: ((Int) -> Void)? = nil,
        onNearEnd: ((Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.showTopInfo = showTopInfo
        self.showPageIndicator = showPageIndicator
        self.onPageChanged = onPageChanged
        self.onNearEnd = onNearEnd
        self.content = content
    }
    
    var body: some View {
        VStack {
            // 顶部信息（可选）
            if showTopInfo {
                HStack {
                    Text("当前页面: \(currentIndex + 1)")
                    Spacer()
                    Text("总共: \(items.count)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
            
            // TabView实现分页效果
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: showPageIndicator ? .always : .never))
            .onChange(of: currentIndex) { newValue in
                onPageChanged?(newValue)
                
                // 检查是否接近末尾
                if newValue >= items.count - 5 {
                    onNearEnd?(newValue)
                }
            }
        }
    }
}

// MARK: - 方法2：ScrollView + ScrollViewReader (更灵活)
struct ScrollViewPagingExample: View {
    var body: some View {
        let cardData = Array(0..<100).map { index in
            CardData(
                id: index,
                title: "卡片 \(index + 1)",
                subtitle: "ScrollView实现的分页效果",
                color: [.cyan, .mint, .indigo, .yellow, .brown, .gray][index % 6]
            )
        }
        
        ALScrollViewPaging(
            items: cardData,
            showControls: true,
            showIndicator: true,
            maxIndicatorDots: 10,
            onPageChanged: { index in
                print("ScrollView切换到: \(index)")
            }
        ) { card in
            CardView(card: card)
        }
    }
}

// MARK: - 可复用的ScrollView分页组件
struct ALScrollViewPaging<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let showControls: Bool
    let showIndicator: Bool
    let maxIndicatorDots: Int
    let onPageChanged: ((Int) -> Void)?
    let content: (Item) -> Content
    
    @State private var currentIndex = 0
    
    init(
        items: [Item],
        showControls: Bool = false,
        showIndicator: Bool = true,
        maxIndicatorDots: Int = 10,
        onPageChanged: ((Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.showControls = showControls
        self.showIndicator = showIndicator
        self.maxIndicatorDots = maxIndicatorDots
        self.onPageChanged = onPageChanged
        self.content = content
    }
    
    var body: some View {
        VStack {
            // 顶部控制（可选）
            if showControls {
                HStack {
                    Button("上一页") {
                        if currentIndex > 0 {
                            currentIndex -= 1
                        }
                    }
                    .disabled(currentIndex == 0)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(items.count)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("下一页") {
                        if currentIndex < items.count - 1 {
                            currentIndex += 1
                        }
                    }
                    .disabled(currentIndex == items.count - 1)
                }
                .padding()
            }
            
            // ScrollView实现
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            content(item)
                                .frame(width: UIScreen.main.bounds.width - 40)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: currentIndex) { newValue in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                    onPageChanged?(newValue)
                }
                .onAppear {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
            
            // 自定义页面指示器（可选）
            if showIndicator {
                HStack(spacing: 6) {
                    ForEach(0..<min(items.count, maxIndicatorDots), id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? .blue : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                    
                    if items.count > maxIndicatorDots {
                        Text("...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - 方法3：LazyVStack + ScrollViewReader (垂直滑动)
struct LazyVStackPagingExample: View {
    var body: some View {
        let cardData = Array(0..<50).map { index in
            CardData(
                id: index,
                title: "垂直卡片 \(index + 1)",
                subtitle: "支持垂直滑动的卡片效果",
                color: [.red, .orange, .yellow, .green, .blue, .purple][index % 6]
            )
        }
        
        ALVerticalPaging(
            items: cardData,
            showControls: true,
            autoScroll: false,
            autoScrollInterval: 3.0,
            itemHeight: 400,
            onPageChanged: { index in
                print("垂直滑动到: \(index)")
            }
        ) { card in
            CardView(card: card)
        }
    }
}

// MARK: - 可复用的垂直滑动分页组件
struct ALVerticalPaging<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let showControls: Bool
    let autoScroll: Bool
    let autoScrollInterval: TimeInterval
    let itemHeight: CGFloat
    let onPageChanged: ((Int) -> Void)?
    let content: (Item) -> Content
    
    @State private var currentIndex = 0
    @State private var isAutoScrolling = false
    @State private var scrollTimer: Timer?
    
    init(
        items: [Item],
        showControls: Bool = false,
        autoScroll: Bool = false,
        autoScrollInterval: TimeInterval = 3.0,
        itemHeight: CGFloat = 400,
        onPageChanged: ((Int) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.showControls = showControls
        self.autoScroll = autoScroll
        self.autoScrollInterval = autoScrollInterval
        self.itemHeight = itemHeight
        self.onPageChanged = onPageChanged
        self.content = content
    }
    
    var body: some View {
        VStack {
            // 控制面板（可选）
            if showControls {
                HStack {
                    Button(action: {
                        isAutoScrolling.toggle()
                        if isAutoScrolling {
                            startAutoScroll()
                        } else {
                            stopAutoScroll()
                        }
                    }) {
                        Image(systemName: isAutoScrolling ? "pause.fill" : "play.fill")
                        Text(isAutoScrolling ? "停止" : "自动播放")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    VStack {
                        Text("当前: \(currentIndex + 1)")
                        Text("总数: \(items.count)")
                    }
                    .font(.caption)
                }
                .padding()
            }
            
            // 垂直滑动实现
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            content(item)
                                .frame(height: itemHeight)
                                .id(index)
                                .onAppear {
                                    currentIndex = index
                                    onPageChanged?(index)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    if autoScroll && !isAutoScrolling {
                        isAutoScrolling = true
                        startAutoScroll()
                    }
                }
                .onDisappear {
                    stopAutoScroll()
                }
            }
        }
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        
        scrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { _ in
            guard isAutoScrolling else { return }
            
            let nextIndex = (currentIndex + 1) % items.count
            currentIndex = nextIndex
            onPageChanged?(nextIndex)
        }
    }
    
    private func stopAutoScroll() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
}

// MARK: - 通用卡片视图
struct CardView: View {
    let card: CardData
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            card.color.opacity(0.8),
                            card.color.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: card.color.opacity(0.3), radius: 15, x: 0, y: 5)
            
            VStack(spacing: 20) {
                // 图标
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    Text(card.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(card.subtitle)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // 交互按钮
                HStack(spacing: 15) {
                    Button(action: {
                        print("点击了卡片 \(card.id)")
                    }) {
                        Label("详情", systemImage: "info.circle")
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.white.opacity(0.2))
                            )
                    }
                    
                    Button(action: {
                        print("收藏了卡片 \(card.id)")
                    }) {
                        Label("收藏", systemImage: "heart")
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.white.opacity(0.2))
                            )
                    }
                }
            }
            .padding(30)
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - 数据模型
struct CardData: Identifiable {
    
    let uuid = UUID().uuidString
    
    let id: Int
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - 预览
struct ALScrollCardView_Previews: PreviewProvider {
    static var previews: some View {
        ALScrollCardView()
    }
}
