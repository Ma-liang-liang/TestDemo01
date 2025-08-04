//
//  ALSheetPage.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/9.
//
import SwiftUI

/// 一个半透明的、底部有固定高度操作区域的SwiftUI视图。
/// 点击上半透明区域会触发 dismiss 操作，点击底部粉色区域会触发自定义操作。

struct ALSheetPage: View {
    
    // 1. 移除 onDismiss 属性
    var onDismiss: () -> Void
    
    /// 点击底部粉色区域时触发的回调闭包
    var onPinkAreaTap: () -> Void
    
    // 2. 添加 presentationMode 环境值
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showContent = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    triggerDismissAnimation()
                }
            
            VStack {
                Spacer()
                
                VStack {
                    Text("粉色区域")
                        .foregroundColor(.white)
                        .font(.title)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .background(Color.pink)
                .onTapGesture {
                    onPinkAreaTap()
                }
                .offset(y: showContent ? 0 : 420)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            showContent = false
            triggerPresentAnimation()
        }
    }
    
    private func triggerPresentAnimation() {
        withAnimation(.spring()) {
            showContent = true
        }
    }
    
    private func triggerDismissAnimation() {
        if #available(iOS 17.0, *) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.showContent = false
            } completion: {
                // 3. 直接调用环境中的 dismiss
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            // Fallback on earlier versions
            withAnimation {
                self.showContent = false
            }
            // 0.25秒后执行（与动画持续时间匹配）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                print("动画应该完成了")
                // 在这里执行动画完成后的操作
                presentationMode.wrappedValue.dismiss()
            }
        }
        
        
        
    }
}

#Preview {
    ALSheetPage(onDismiss: {
        print("预览模式：Dismiss 被触发")
    }, onPinkAreaTap: {
        print("预览模式：Pink Area Tap 被触发")
    })
}
