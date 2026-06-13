//
//  ImageShopPage.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/26.
//

import SwiftUI

struct ImageShopItem: Identifiable {
    let id = UUID()
    let imageURL: String
    let title: String
    let price: String
    let rating: Double
    let tag: String?
}

struct ImageShopPage: View {
    @State private var selectedCategory = 0
    @State private var showDetail = false
    @State private var selectedItem: ImageShopItem?
    @State private var selectedCardFrame: CGRect = .zero
    @Namespace private var animation

    let categories = ["All", "Trending", "New", "Popular"]

    let items: [ImageShopItem] = [
        ImageShopItem(imageURL: "https://picsum.photos/id/10/600/600", title: "Forest Path", price: "$24.99", rating: 4.8, tag: "Hot"),
        ImageShopItem(imageURL: "https://picsum.photos/id/14/600/600", title: "Mountain Lake", price: "$19.99", rating: 4.6, tag: nil),
        ImageShopItem(imageURL: "https://picsum.photos/id/15/600/600", title: "Hilltop View", price: "$29.99", rating: 4.9, tag: "New"),
        ImageShopItem(imageURL: "https://picsum.photos/id/16/600/600", title: "Ocean Waves", price: "$15.99", rating: 4.5, tag: nil),
        ImageShopItem(imageURL: "https://picsum.photos/id/17/600/600", title: "Wooden Pier", price: "$22.99", rating: 4.7, tag: "Hot"),
        ImageShopItem(imageURL: "https://picsum.photos/id/18/600/600", title: "Misty Forest", price: "$18.99", rating: 4.4, tag: nil),
        ImageShopItem(imageURL: "https://picsum.photos/id/19/600/600", title: "Desert Road", price: "$26.99", rating: 4.8, tag: "New"),
        ImageShopItem(imageURL: "https://picsum.photos/id/20/600/600", title: "River Stream", price: "$21.99", rating: 4.6, tag: nil),
        ImageShopItem(imageURL: "https://picsum.photos/id/21/600/600", title: "Snow Peak", price: "$32.99", rating: 4.9, tag: "Hot"),
        ImageShopItem(imageURL: "https://picsum.photos/id/22/600/600", title: "Night Sky", price: "$27.99", rating: 4.7, tag: nil),
        ImageShopItem(imageURL: "https://picsum.photos/id/23/600/600", title: "Green Valley", price: "$20.99", rating: 4.5, tag: "New"),
        ImageShopItem(imageURL: "https://picsum.photos/id/24/600/600", title: "Autumn Leaves", price: "$23.99", rating: 4.8, tag: nil),
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if !showDetail {
                    CGCustomNavigationBar(config: navBarConfig)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        categoryTabs

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(items) { item in
                                ImageShopCard(item: item, animation: animation)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .preference(key: CardFrameKey.self, value: [item.id: geo.frame(in: .global)])
                                        }
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                                            selectedItem = item
                                            showDetail = true
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .onPreferenceChange(CardFrameKey.self) { value in
                selectedCardFrame = value.values.first ?? .zero
            }

            if showDetail, let item = selectedItem {
                ImageShopDetailView(
                    item: item,
                    animation: animation,
                    onDismiss: {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            showDetail = false
                            selectedItem = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    private var navBarConfig: CGNavigationBarConfig {
        CGNavigationBarConfig(
            title: "Image Shop",
            showBackButton: true,
            rightBarItems: [
                CGNavigationBarItem(icon: "cart") {}
            ]
        )
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories.indices, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = index
                        }
                    } label: {
                        Text(categories[index])
                            .font(.system(size: 14, weight: selectedCategory == index ? .bold : .medium))
                            .foregroundColor(selectedCategory == index ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == index
                                    ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(.ultraThinMaterial)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct ImageShopCard: View {
    let item: ImageShopItem
    var animation: Namespace.ID
    @State private var isLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: item.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear { withAnimation(.easeIn) { isLoaded = true } }
                    case .failure:
                        Rectangle()
                            .fill(.quaternary)
                            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 160)
                .clipped()
                .matchedGeometryEffect(id: "image_\(item.id)", in: animation)

                if let tag = item.tag {
                    Text(tag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            tag == "Hot"
                                ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "title_\(item.id)", in: animation)

                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 11))
                        Text(String(format: "%.1f", item.rating))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(item.price)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)
                        .matchedGeometryEffect(id: "price_\(item.id)", in: animation)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .opacity(isLoaded ? 1 : 0.6)
    }
}

struct ImageShopDetailView: View {
    let item: ImageShopItem
    var animation: Namespace.ID
    var onDismiss: () -> Void

    @State private var showBuyAlert = false
    @State private var isFavorite = false
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroImage

                        VStack(alignment: .leading, spacing: 16) {
                            titleRow
                            statsRow
                            Divider()
                            descriptionSection
                            Divider()
                            infoBoxes
                            buyButton
                        }
                        .padding(20)
                    }
                }

                topBar
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                    contentOpacity = 1
                    contentOffset = 0
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private var heroImage: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: item.imageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 400)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 400)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 400)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.secondary))
                @unknown default:
                    EmptyView()
                }
            }
            .matchedGeometryEffect(id: "image_\(item.id)", in: animation)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            HStack {
                Spacer()
                Button { isFavorite.toggle() } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFavorite ? .red : .white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(16)
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                Button { onDismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 50)
            Spacer()
        }
    }

    private var titleRow: some View {
        HStack {
            Text(item.title)
                .font(.system(size: 26, weight: .bold))
                .matchedGeometryEffect(id: "title_\(item.id)", in: animation)
            Spacer()
            Text(item.price)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
                .matchedGeometryEffect(id: "price_\(item.id)", in: animation)
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundColor(.yellow)
                Text(String(format: "%.1f", item.rating)).fontWeight(.semibold)
            }
            HStack(spacing: 4) {
                Image(systemName: "eye.fill").foregroundColor(.secondary)
                Text("2.4k views")
            }
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle").foregroundColor(.secondary)
                Text("856 downloads")
            }
        }
        .font(.system(size: 13))
        .foregroundColor(.secondary)
        .opacity(contentOpacity)
        .offset(y: contentOffset)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 18, weight: .semibold))
            Text("This is a stunning high-resolution photograph captured in natural lighting. Perfect for personal projects, commercial use, or as wall art. Available in multiple resolutions and formats.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
    }

    private var infoBoxes: some View {
        HStack(spacing: 12) {
            DetailInfoBox(title: "Resolution", value: "4K")
            DetailInfoBox(title: "Format", value: "JPEG")
            DetailInfoBox(title: "License", value: "Standard")
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
    }

    private var buyButton: some View {
        Button {
            showBuyAlert = true
        } label: {
            HStack {
                Image(systemName: "cart.fill")
                Text("Add to Cart").fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
        }
        .padding(.top, 8)
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .alert("Added to Cart!", isPresented: $showBuyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(item.title) has been added to your cart.")
        }
    }
}

struct DetailInfoBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(12)
    }
}

struct CardFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension ImageShopItem: Hashable {
    static func == (lhs: ImageShopItem, rhs: ImageShopItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    ImageShopPage()
}
