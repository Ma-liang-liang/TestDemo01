//
//  HUDManager.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/4.
//
import SwiftUI
import Combine

class ALHUDManager: ObservableObject {
    static let shared = ALHUDManager()
    
    // 使用枚举来明确区分不同状态
    enum HUDState {
        case hidden
        case loading(message: String?)
        case toast(message: String)
    }
    
    @Published private(set) var state: HUDState = .hidden
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func showLoading(message: String? = nil) {
        DispatchQueue.main.async {
            self.state = .loading(message: message)
        }
    }
    
    func showToast(message: String, duration: Double = 1.5) {
        DispatchQueue.main.async {
            self.state = .toast(message: message)
            
            // 自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if case .toast = self.state {
                    self.hide()
                }
            }
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.state = .hidden
        }
    }
}

struct ALHUDModifier: ViewModifier {
    @ObservedObject private var manager = ALHUDManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
                // 根据状态控制交互
                .disabled(manager.state.isLoading)
                .allowsHitTesting(!manager.state.isLoading)
            
            if manager.state.isVisible {
                hudContent
                    .transition(.opacity)
                    .zIndex(1) // 确保在最上层
            }
        }
    }
    
    @ViewBuilder
    private var hudContent: some View {
        switch manager.state {
        case .loading(let message):
            ALLoadingHUDView(message: message)
        case .toast(let message):
            ALToastHUDView(message: message)
        case .hidden:
            EmptyView()
        }
    }
}

// MARK: - HUD 视图组件
private struct ALLoadingHUDView: View {
    let message: String?
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 14))
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .foregroundColor(.white)
    }
}

private struct ALToastHUDView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

// MARK: - 扩展和辅助
extension ALHUDManager.HUDState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var isVisible: Bool {
        if case .hidden = self { return false }
        return true
    }
}

extension View {
    func alHudView() -> some View {
        self.modifier(ALHUDModifier())
    }
}
