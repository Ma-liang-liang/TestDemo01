//
//  ComplexUIDemo.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/8.
//

import SwiftUI

import SwiftUI

struct ComplexUIDemo: View {
    @State private var selectedTab = 0
    @State private var isShowingSettings = false
    @State private var isLiked = false
    @State private var likeCount = 243
    @State private var showAllPhotos = false
    @State private var selectedPhotoIndex = 0
    @State private var isAnimating = false
    
    @Environment(\.dismiss) private var dismiss // 获取 dismiss 方法

    
    let posts: [Post] = [
        Post(id: 1, imageName: "photo1", title: "Mountain Adventure", likes: 124, comments: 32),
        Post(id: 2, imageName: "photo2", title: "Beach Sunset", likes: 89, comments: 12),
        Post(id: 3, imageName: "photo3", title: "City Life", likes: 56, comments: 8)
    ]
    
    let photos = ["photo1", "photo2", "photo3", "photo4", "photo5", "photo6"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部背景和头像
                    ZStack(alignment: .bottom) {
                        Image("header")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        HStack {
                            Spacer()
                            
                            Image("profile")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.pink, lineWidth: 4))
                                .offset(y: 60)
                                .shadow(radius: 10)
                            
                            Spacer()
                        }
                    }
                    .padding(.bottom, 60)
                    
                    // 用户信息
                    VStack(spacing: 8) {
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundStyle(Color.red)
                        }
                        
                        Text("Alex Johnson")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("@alexjohnson")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Digital designer & photographer. Love to travel and capture moments.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("1,234")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("567")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("89")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 16)
                        
                        // 操作按钮
                        HStack(spacing: 16) {
                            Button(action: {
                                // 关注动作
                            }) {
                                Text("Follow")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                            }
                        
                            Button(action: {
                                isShowingSettings.toggle()
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .sheet(isPresented: $isShowingSettings) {
                                SettingsView()
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // 照片网格
                    if !showAllPhotos {
                        PhotoGridView(photos: Array(photos.prefix(6)), showAllPhotos: $showAllPhotos)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    } else {
                        FullPhotoView(photos: photos, selectedIndex: $selectedPhotoIndex, showAllPhotos: $showAllPhotos)
                            .frame(height: 300)
                            .padding(.bottom, 20)
                    }
                    
                    // 选项卡
                    Picker("", selection: $selectedTab) {
                        Text("Posts").tag(0)
                        Text("Likes").tag(1)
                        Text("Saved").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // 动态内容
                    if selectedTab == 0 {
                        PostsView(posts: posts)
                    } else if selectedTab == 1 {
                        LikesView()
                    } else {
                        SavedView()
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                    isAnimating.toggle()
                }
            }
        }
    }
}

// MARK: - 子视图

struct PhotoGridView: View {
    let photos: [String]
    @Binding var showAllPhotos: Bool
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                ForEach(photos.indices, id: \.self) { index in
                    Image(photos[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: (UIScreen.main.bounds.width - 40) / 3, height: (UIScreen.main.bounds.width - 40) / 3)
                        .clipped()
                        .onTapGesture {
                            showAllPhotos = true
                        }
                }
            }
            
            if photos.count == 6 {
                Button(action: {
                    showAllPhotos = true
                }) {
                    Text("View All Photos")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
        }
    }
}

struct FullPhotoView: View {
    let photos: [String]
    @Binding var selectedIndex: Int
    @Binding var showAllPhotos: Bool
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(photos.indices, id: \.self) { index in
                Image(photos[index])
                    .resizable()
                    .scaledToFit()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .overlay(
            Button(action: {
                showAllPhotos = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16),
            alignment: .topTrailing
        )
        .frame(height: 300)
        .background(Color.black)
    }
}

struct PostsView: View {
    let posts: [Post]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(posts) { post in
                PostView(post: post)
                    .padding(.horizontal)
            }
        }
    }
}

struct PostView: View {
    let post: Post
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image("profile")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text("Alex Johnson")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("2 hours ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            Text(post.title)
                .font(.headline)
            
            Image(post.imageName)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                Button(action: {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(likeCount)")
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                }
            }
            .foregroundColor(.primary)
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct LikesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())
            
            Text("No Likes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("When you like posts, they'll appear here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 80)
    }
}

struct SavedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text("No Saved Posts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save posts to easily find them later.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 80)
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: Text("Edit Profile")) {
                        SettingRow(icon: "person", title: "Edit Profile")
                    }
                    
                    NavigationLink(destination: Text("Account Settings")) {
                        SettingRow(icon: "gear", title: "Account Settings")
                    }
                }
                
                Section {
                    NavigationLink(destination: Text("Notifications")) {
                        SettingRow(icon: "bell", title: "Notifications")
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        SettingRow(icon: "lock", title: "Privacy")
                    }
                }
                
                Section {
                    Button(action: {
                        // 登出逻辑
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        SettingRow(icon: "arrow.left.square", title: "Log Out", color: .red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(color)
        }
    }
}

// MARK: - 数据模型

struct Post: Identifiable {
    let id: Int
    let imageName: String
    let title: String
    let likes: Int
    let comments: Int
}

// MARK: - 预览

struct ComplexUIDemo_Previews: PreviewProvider {
    static var previews: some View {
        ComplexUIDemo()
    }
}

#Preview {
    ComplexUIDemo()
}
