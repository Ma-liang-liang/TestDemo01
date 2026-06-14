//
//  ALChatPage.swift
//  TestDemo
//
//  Created by Qoder.
//

import SwiftUI
import Combine

// MARK: - =================== 数据模型 ===================

/// 消息类型
enum ChatMessageType: String {
    case text
    case image
    case system
}

/// 消息发送状态
enum ChatMessageStatus {
    case sending
    case sent
    case failed
}

/// 聊天用户
struct ChatUser {
    let id: String
    let name: String
    let avatar: String // SF Symbol name
    let isOnline: Bool
}

/// 聊天消息
struct ChatMessage: Identifiable {
    let id = UUID().uuidString
    let content: String
    let type: ChatMessageType
    let sender: ChatUser
    let timestamp: Date
    var status: ChatMessageStatus
    var isRead: Bool
    
    var isFromMe: Bool {
        sender.id == "me"
    }
    
    /// 格式化时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    /// 是否需要显示时间戳（与上一条消息间隔超过 5 分钟）
    static func shouldShowTimestamp(current: Date, previous: Date?) -> Bool {
        guard let previous = previous else { return true }
        return current.timeIntervalSince(previous) > 300 // 5分钟
    }
}

// MARK: - =================== ViewModel ===================

class ALChatViewModel: ObservableObject {
    
    // 当前用户
    let currentUser = ChatUser(id: "me", name: "我", avatar: "person.circle.fill", isOnline: true)
    
    // 对方用户
    let peerUser = ChatUser(id: "peer", name: "小助手", avatar: "star.circle.fill", isOnline: true)
    
    // 消息列表
    @Published var messages: [ChatMessage] = []
    
    // 输入框文本
    @Published var inputText: String = ""
    
    // 是否正在输入中
    @Published var isTyping: Bool = false
    
    // 是否显示附件面板
    @Published var showAttachmentPanel: Bool = false
    
    // 是否显示图片选择器
    @Published var showImagePicker: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockMessages()
    }
    
    // MARK: - 加载模拟数据
    private func loadMockMessages() {
        let now = Date()
        messages = [
            ChatMessage(
                content: "你好！有什么可以帮助你的吗？",
                type: .text, sender: peerUser,
                timestamp: now.addingTimeInterval(-3600),
                status: .sent, isRead: true
            ),
            ChatMessage(
                content: "你好，我想了解一下你们的产品",
                type: .text, sender: currentUser,
                timestamp: now.addingTimeInterval(-3500),
                status: .sent, isRead: true
            ),
            ChatMessage(
                content: "当然！我们的产品主要包括移动应用开发、后端服务和数据分析平台。",
                type: .text, sender: peerUser,
                timestamp: now.addingTimeInterval(-3400),
                status: .sent, isRead: true
            ),
            ChatMessage(
                content: "听起来很不错，能详细介绍一下移动应用开发这块吗？",
                type: .text, sender: currentUser,
                timestamp: now.addingTimeInterval(-3000),
                status: .sent, isRead: true
            ),
            ChatMessage(
                content: "我们支持 iOS 和 Android 双平台开发，使用 Swift/Kotlin 原生开发，也支持 Flutter 跨平台方案。",
                type: .text, sender: peerUser,
                timestamp: now.addingTimeInterval(-2800),
                status: .sent, isRead: true
            ),
            ChatMessage(
                content: "费用方面是怎样的？",
                type: .text, sender: currentUser,
                timestamp: now.addingTimeInterval(-2600),
                status: .sent, isRead: true
            ),
            ChatMessage(
                content: "费用根据项目复杂度而定，我们可以安排一个详细的需求沟通会议。😊",
                type: .text, sender: peerUser,
                timestamp: now.addingTimeInterval(-2400),
                status: .sent, isRead: true
            ),
        ]
    }
    
    // MARK: - 发送消息
    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let msg = ChatMessage(
            content: trimmed,
            type: .text,
            sender: currentUser,
            timestamp: Date(),
            status: .sending,
            isRead: false
        )
        messages.append(msg)
        inputText = ""
        
        // 模拟发送成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let idx = self.messages.firstIndex(where: { $0.id == msg.id }) else { return }
            self.messages[idx].status = .sent
        }
        
        // 模拟对方正在输入 + 自动回复
        simulateReply(to: trimmed)
    }
    
    // MARK: - 模拟对方回复
    private func simulateReply(to text: String) {
        // 显示正在输入
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isTyping = true
        }
        
        // 生成回复
        let replyText = Self.generateReply(for: text)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            self.isTyping = false
            let reply = ChatMessage(
                content: replyText,
                type: .text,
                sender: self.peerUser,
                timestamp: Date(),
                status: .sent,
                isRead: true
            )
            self.messages.append(reply)
        }
    }
    
    // MARK: - 简单关键词回复
    private static func generateReply(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("价格") || lower.contains("费用") || lower.contains("多少钱") {
            return "关于价格，我们提供多种套餐方案，具体可以查看详细报价单。💰"
        } else if lower.contains("时间") || lower.contains("多久") || lower.contains("周期") {
            return "项目周期一般在 2-8 周，具体取决于功能复杂度。⏰"
        } else if lower.contains("谢谢") || lower.contains("感谢") {
            return "不客气！有其他问题随时联系我。🙌"
        } else if lower.contains("你好") || lower.contains("嗨") || lower.contains("hi") || lower.contains("hello") {
            return "你好！很高兴为你服务~ 👋"
        } else if lower.contains("再见") || lower.contains("拜拜") {
            return "再见，祝你生活愉快！👋"
        } else if lower.contains("功能") || lower.contains("feature") {
            return "我们支持消息推送、实时聊天、文件传输、视频通话等丰富功能。✨"
        } else {
            let replies = [
                "好的，我已经记录下来了。",
                "收到，稍后会有专人跟进。",
                "明白了，还有什么需要了解的吗？",
                "这是一个好问题，让我想想...🤔",
                "没问题，我们会尽快处理。",
            ]
            return replies.randomElement() ?? "收到！"
        }
    }
    
    // MARK: - 发送图片（模拟）
    func sendImage() {
        let msg = ChatMessage(
            content: "[图片]",
            type: .image,
            sender: currentUser,
            timestamp: Date(),
            status: .sent,
            isRead: true
        )
        messages.append(msg)
        simulateReply(to: "图片")
    }
    
    // MARK: - 删除消息
    func deleteMessage(at offsets: IndexSet) {
        messages.remove(atOffsets: offsets)
    }
    
    // MARK: - 清空聊天记录
    func clearMessages() {
        messages.removeAll()
        let systemMsg = ChatMessage(
            content: "聊天记录已清空",
            type: .system, sender: peerUser,
            timestamp: Date(),
            status: .sent, isRead: true
        )
        messages.append(systemMsg)
    }
    
    // MARK: - 上一条消息时间
    func previousMessageTime(at index: Int) -> Date? {
        guard index > 0 else { return nil }
        return messages[index - 1].timestamp
    }
}

// MARK: - =================== 主视图 ===================

struct ALChatPage: View {
    
    @StateObject private var viewModel = ALChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 导航栏
                chatNavBar(safeAreaTop: geometry.safeAreaInsets.top)
                
                // 消息列表
                messageListView
                
                // 正在输入指示器
                if viewModel.isTyping {
                    typingIndicator
                }
                
                Divider()
                
                // 输入栏
                inputBarView(safeAreaBottom: geometry.safeAreaInsets.bottom)
                
                // 附件面板
                if viewModel.showAttachmentPanel {
                    attachmentPanel
                }
            }
            .ignoresSafeArea(.container, edges: [.top, .bottom])
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                isInputFocused = false
                viewModel.showAttachmentPanel = false
            }
        }
    }
    
    // MARK: - 导航栏
    private func chatNavBar(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(.systemBackground).frame(height: safeAreaTop)
            
            HStack(spacing: 12) {
                // 返回按钮
                Button {
                    CGNavigationManager.shared.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 36, height: 36)
                }
                
                // 头像
                Image(systemName: viewModel.peerUser.avatar)
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                
                // 名称 + 在线状态
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.peerUser.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.peerUser.isOnline ? .green : .gray)
                            .frame(width: 6, height: 6)
                        Text(viewModel.peerUser.isOnline ? "在线" : "离线")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 更多操作
                Menu {
                    Button {
                        viewModel.clearMessages()
                    } label: {
                        Label("清空记录", systemImage: "trash")
                    }
                    Button { } label: {
                        Label("搜索聊天", systemImage: "magnifyingglass")
                    }
                    Button { } label: {
                        Label("查看资料", systemImage: "person.crop.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 消息列表
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    // 顶部提示
                    Text("—— 以上是历史消息 ——")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                    
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        VStack(spacing: 4) {
                            // 时间戳
                            if ChatMessage.shouldShowTimestamp(
                                current: message.timestamp,
                                previous: viewModel.previousMessageTime(at: index)
                            ) {
                                Text(formatTimestamp(message.timestamp))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 6)
                            }
                            
                            // 系统消息
                            if message.type == .system {
                                systemMessageView(message)
                            } else {
                                messageBubbleView(message)
                            }
                        }
                        .id(message.id)
                    }
                    
                    // 底部占位
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isTyping) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }
    
    // MARK: - 系统消息
    private func systemMessageView(_ message: ChatMessage) -> some View {
        Text(message.content)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.6))
            .cornerRadius(10)
    }
    
    // MARK: - 消息气泡
    private func messageBubbleView(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromMe { Spacer(minLength: 48) }
            
            if !message.isFromMe {
                // 对方头像
                Image(systemName: message.sender.avatar)
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
            }
            
            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                // 气泡
                if message.type == .image {
                    imageBubble(message)
                } else {
                    textBubble(message)
                }
                
                // 状态指示器（仅自己发的消息）
                if message.isFromMe {
                    messageStatusView(message)
                }
            }
            
            if !message.isFromMe { Spacer(minLength: 48) }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.content
            } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
            if message.isFromMe {
                Button(role: .destructive) {
                    if let idx = viewModel.messages.firstIndex(where: { $0.id == message.id }) {
                        viewModel.deleteMessage(at: IndexSet(integer: idx))
                    }
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - 文本气泡
    private func textBubble(_ message: ChatMessage) -> some View {
        Text(message.content)
            .font(.system(size: 15))
            .foregroundColor(message.isFromMe ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isFromMe
                ? Color.accentColor
                : Color(.systemBackground)
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 图片气泡
    private func imageBubble(_ message: ChatMessage) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)
            
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))
        }
        .cornerRadius(12)
    }
    
    // MARK: - 消息状态
    private func messageStatusView(_ message: ChatMessage) -> some View {
        HStack(spacing: 4) {
            Text(message.formattedTime)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            switch message.status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.6)
            case .sent:
                Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark")
                    .font(.system(size: 10))
                    .foregroundColor(message.isRead ? .blue : .secondary)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - 正在输入
    private var typingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.peerUser.avatar)
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                            value: viewModel.isTyping
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - 输入栏
    private func inputBarView(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                // 附件按钮
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.showAttachmentPanel.toggle()
                        isInputFocused = false
                    }
                } label: {
                    Image(systemName: viewModel.showAttachmentPanel ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                }
                
                // 输入框
                HStack(alignment: .center, spacing: 0) {
                    TextField("输入消息...", text: $viewModel.inputText, axis: .vertical)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .font(.system(size: 15))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .onTapGesture {
                            viewModel.showAttachmentPanel = false
                        }
                }
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                // 发送按钮 / 语音按钮
                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    }
                } else {
                    Button {
                        viewModel.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // 底部安全区
            Color(.systemBackground)
                .frame(height: safeAreaBottom)
        }
    }
    
    // MARK: - 附件面板
    private var attachmentPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                attachmentItem(icon: "photo", title: "相册", color: .blue) {
                    viewModel.sendImage()
                    viewModel.showAttachmentPanel = false
                }
                attachmentItem(icon: "camera", title: "拍照", color: .green) {
                    viewModel.sendImage()
                    viewModel.showAttachmentPanel = false
                }
                attachmentItem(icon: "doc", title: "文件", color: .orange) { }
                attachmentItem(icon: "location", title: "位置", color: .red) { }
            }
            
            HStack(spacing: 0) {
                attachmentItem(icon: "creditcard", title: "转账", color: .purple) { }
                attachmentItem(icon: "gift", title: "红包", color: .pink) { }
                attachmentItem(icon: "video", title: "视频通话", color: .teal) { }
                attachmentItem(icon: "ellipsis", title: "更多", color: .gray) { }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func attachmentItem(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - 辅助方法
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let last = viewModel.messages.last else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - =================== 预览 ===================
#Preview {
    ALChatPage()
}
