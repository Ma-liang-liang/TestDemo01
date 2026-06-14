//
//  HotViewController.swift
//  TestDemo01
//
//  Created by Assistant on 2025/1/20.
//

import UIKit
import JXSegmentedView

class HotViewController: SKBaseController {
    
    // MARK: - UI Components
    private let collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Data
    private var dataList: [String] = []
    
    // MARK: - Callback
    var onRefreshStart: (() -> Void)?
    var onRefreshEnd: (() -> Void)?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 160, height: 120)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 160, height: 120)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 配置CollectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(HotCollectionViewCell.self, forCellWithReuseIdentifier: "HotCell")
        
        // 配置下拉刷新
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadInitialData() {
        dataList = [
            "Hot Topic 1",
            "Hot Topic 2",
            "Hot Topic 3",
            "Hot Topic 4",
            "Hot Topic 5",
            "Hot Topic 6",
            "Hot Topic 7",
            "Hot Topic 8"
        ]
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func handleRefresh() {
        // 通知父控制器开始刷新动画
        onRefreshStart?()
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // 添加新数据
            let newItems = [
                "New Hot Topic \(Int.random(in: 1...100))",
                "New Hot Topic \(Int.random(in: 1...100))"
            ]
            self.dataList.insert(contentsOf: newItems, at: 0)
            
            // 更新UI
            self.collectionView.reloadData()
            self.refreshControl.endRefreshing()
            
            // 通知父控制器结束刷新动画
            self.onRefreshEnd?()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HotViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotCell", for: indexPath) as! HotCollectionViewCell
        cell.configure(with: dataList[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HotViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected: \(dataList[indexPath.item])")
    }
}

// MARK: - Custom Cell
class HotCollectionViewCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let backgroundImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 背景
        backgroundImageView.backgroundColor = .systemOrange.withAlphaComponent(0.3)
        backgroundImageView.layer.cornerRadius = 8
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageView)
        
        // 标题
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

extension HotViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
