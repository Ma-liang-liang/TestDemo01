//
//  CustomSwipeBackView.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/18.
//

import SwiftUI

import SwiftUI

struct CustomSwipeBackView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGSize = .zero
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(x: max(0, dragOffset.width)) // 限制右滑
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 只允许从左侧边缘右滑
                        if value.startLocation.x < 20 && value.translation.width > 0 {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        // 滑动超过屏幕1/3时触发返回
                        if value.predictedEndTranslation.width > UIScreen.main.bounds.width / 3 {
                            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                                dragOffset.width = UIScreen.main.bounds.width
                            }
                            dismiss()
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .transition(.move(edge: .leading)) // 自定义转场动画
    }
}

#Preview {
    CustomSwipeBackView {
        Text("哈哈哈哈")
    }
}
