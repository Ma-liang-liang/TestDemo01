//
//  FollowViewController.swift
//  TestDemo01
//
//  Created by Assistant on 2025/1/20.
//

import UIKit
import JXSegmentedView

class FollowViewController: SKBaseController {
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Data
    private var dataList: [String] = []
    
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
        
        // 配置TableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FollowCell")
        
        // 配置下拉刷新
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadInitialData() {
        dataList = [
            "Follow Item 1",
            "Follow Item 2",
            "Follow Item 3",
            "Follow Item 4",
            "Follow Item 5",
            "Follow Item 6",
            "Follow Item 7",
            "Follow Item 8",
            "Follow Item 9",
            "Follow Item 10"
        ]
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func handleRefresh() {
        // 通知父控制器开始刷新动画
        onRefreshStart?()
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 添加新数据
            let newItems = [
                "New Follow Item \(Int.random(in: 1...100))",
                "New Follow Item \(Int.random(in: 1...100))",
                "New Follow Item \(Int.random(in: 1...100))"
            ]
            self.dataList.insert(contentsOf: newItems, at: 0)
            
            // 更新UI
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
            
            // 通知父控制器结束刷新动画
            self.onRefreshEnd?()
        }
    }
}

// MARK: - UITableViewDataSource
extension FollowViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowCell", for: indexPath)
        cell.textLabel?.text = dataList[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FollowViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Selected: \(dataList[indexPath.row])")
    }
}

// 在每个子控制器中添加这个扩展
extension FollowViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
