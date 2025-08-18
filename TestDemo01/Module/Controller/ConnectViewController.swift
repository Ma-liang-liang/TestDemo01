//
//  ConnectViewController.swift
//  TestDemo01
//
//  Created by Assistant on 2025/1/20.
//

import UIKit
import JXSegmentedView

class ConnectViewController: SKBaseController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Data
    private var dataList: [ConnectItem] = []
    
    // MARK: - Callback
    var onRefreshStart: (() -> Void)?
    var onRefreshEnd: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 配置ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        
        // 配置下拉刷新
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        // 配置ContentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置StackView
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadInitialData() {
        dataList = [
            ConnectItem(title: "Connect with Friends", subtitle: "Find and connect with your friends", icon: "person.2.fill"),
            ConnectItem(title: "Join Communities", subtitle: "Discover communities that match your interests", icon: "person.3.fill"),
            ConnectItem(title: "Share Moments", subtitle: "Share your special moments with others", icon: "camera.fill"),
            ConnectItem(title: "Live Chat", subtitle: "Start real-time conversations", icon: "message.fill"),
            ConnectItem(title: "Video Calls", subtitle: "Connect face-to-face with video calls", icon: "video.fill"),
            ConnectItem(title: "Group Activities", subtitle: "Organize and join group activities", icon: "calendar")
        ]
        updateStackView()
    }
    
    private func updateStackView() {
        // 清除现有视图
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新的卡片视图
        for item in dataList {
            let cardView = createCardView(for: item)
            stackView.addArrangedSubview(cardView)
        }
    }
    
    private func createCardView(for item: ConnectItem) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            iconImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.tag = dataList.firstIndex(where: { $0.title == item.title }) ?? 0
        
        return cardView
    }
    
    // MARK: - Actions
    @objc private func handleRefresh() {
        // 通知父控制器开始刷新动画
        onRefreshStart?()
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            // 添加新数据
            let newItems = [
                ConnectItem(title: "New Connection \(Int.random(in: 1...100))", subtitle: "A new way to connect", icon: "star.fill")
            ]
            self.dataList.insert(contentsOf: newItems, at: 0)
            
            // 更新UI
            self.updateStackView()
            self.refreshControl.endRefreshing()
            
            // 通知父控制器结束刷新动画
            self.onRefreshEnd?()
        }
    }
    
    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cardView = gesture.view else { return }
        let index = cardView.tag
        if index < dataList.count {
            print("Tapped: \(dataList[index].title)")
        }
    }
}

// MARK: - Data Model
struct ConnectItem {
    let title: String
    let subtitle: String
    let icon: String
}

extension ConnectViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
