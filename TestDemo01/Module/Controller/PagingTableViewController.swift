//
//  PagingTableViewController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/20.
//

import UIKit

class PagingTableViewController: UITableViewController {
        
    // 数据源
    private var dataSource: [String] = [
        "第一页内容", "第二页内容", "第三页内容", "第四页内容", "第五页内容"
    ]
    
    // 当前显示的索引
    private var currentIndex: Int = 0
    
    // 屏幕高度
    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    // MARK: - TableView 设置
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        // 关键设置：取消弹性滚动，让滚动更精确
        tableView.bounces = false
        
        // 隐藏滚动指示器
        tableView.showsVerticalScrollIndicator = false
        
        // 取消分割线
        tableView.separatorStyle = .none
        
        // 注册 cell
        tableView.register(FullScreenTableViewCell.self, forCellReuseIdentifier: "FullScreenCell")
        
        // 设置行高为屏幕高度
        tableView.rowHeight = screenHeight
        
        // 重要：设置估算行高为0，确保精确计算
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        
        // 如果有安全区域，需要调整内容边距
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }
}

// MARK: - UITableViewDataSource
extension PagingTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FullScreenCell", for: indexPath) as! FullScreenTableViewCell
        
        // 配置 cell 内容
        cell.configure(with: dataSource[indexPath.row], index: indexPath.row)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PagingTableViewController {
    
    // 设置行高
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight
    }
    
    // 核心方法：实现分页滚动效果
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let currentOffset = scrollView.contentOffset.y
        let targetOffset = targetContentOffset.pointee.y
        
        // 计算当前应该显示的页面索引
        var targetIndex: Int
        
        if velocity.y > 0.5 {
            // 向下快速滑动，切换到下一页
            targetIndex = Int(ceil(currentOffset / screenHeight))
        } else if velocity.y < -0.5 {
            // 向上快速滑动，切换到上一页
            targetIndex = Int(floor(currentOffset / screenHeight))
        } else {
            // 慢速滑动，根据滑动距离判断
            let progress = (targetOffset - currentOffset) / screenHeight
            if abs(progress) > 0.3 {
                // 滑动距离超过30%，切换页面
                targetIndex = progress > 0 ? Int(ceil(currentOffset / screenHeight)) : Int(floor(currentOffset / screenHeight))
            } else {
                // 滑动距离不够，保持当前页面
                targetIndex = Int(round(currentOffset / screenHeight))
            }
        }
        
        // 限制索引范围
        targetIndex = max(0, min(targetIndex, dataSource.count - 1))
        
        // 设置目标偏移量
        targetContentOffset.pointee.y = CGFloat(targetIndex) * screenHeight
        
        // 更新当前索引
        currentIndex = targetIndex
        
        print("切换到第 \(currentIndex + 1) 页")
    }
    
    // 可选：监听滚动完成
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.y / screenHeight)
        currentIndex = page
        print("当前在第 \(currentIndex + 1) 页")
    }
    
    // 可选：监听程序控制的滚动完成
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.y / screenHeight)
        currentIndex = page
        print("滚动动画完成，当前在第 \(currentIndex + 1) 页")
    }
}

// MARK: - 全屏 Cell 定义
class FullScreenTableViewCell: UITableViewCell {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let indexLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 禁用选中效果
        selectionStyle = .none
        
        // 设置容器视图
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 设置标题标签
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        containerView.addSubview(titleLabel)
        
        // 设置内容标签
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.font = UIFont.systemFont(ofSize: 18)
        contentLabel.textAlignment = .center
        contentLabel.textColor = .lightGray
        contentLabel.numberOfLines = 0
        containerView.addSubview(contentLabel)
        
        // 设置索引标签
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.font = UIFont.systemFont(ofSize: 16)
        indexLabel.textAlignment = .center
        indexLabel.textColor = .gray
        containerView.addSubview(indexLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 容器视图填满整个 cell
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // 标题标签
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -50),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            
            // 内容标签
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            contentLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            contentLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 40),
            contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -40),
            
            // 索引标签
            indexLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -100),
            indexLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
    
    func configure(with content: String, index: Int) {
        titleLabel.text = content
        contentLabel.text = "这是第 \(index + 1) 页的详细内容\n向上或向下滑动切换页面"
        indexLabel.text = "\(index + 1) / 5"
        
        // 设置不同页面的背景色
        let colors: [UIColor] = [
            UIColor.systemBlue,
            UIColor.systemGreen,
            UIColor.systemOrange,
            UIColor.systemPurple,
            UIColor.systemRed
        ]
        containerView.backgroundColor = colors[index % colors.count]
    }
}

// MARK: - 扩展：程序控制滚动
extension PagingTableViewController {
    
    // 滚动到指定页面
    func scrollToPage(_ page: Int, animated: Bool = true) {
        guard page >= 0 && page < dataSource.count else { return }
        
        let targetOffset = CGFloat(page) * screenHeight
        tableView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: animated)
        
        if !animated {
            currentIndex = page
        }
    }
    
    // 滚动到下一页
    func scrollToNextPage() {
        let nextPage = min(currentIndex + 1, dataSource.count - 1)
        scrollToPage(nextPage)
    }
    
    // 滚动到上一页
    func scrollToPreviousPage() {
        let previousPage = max(currentIndex - 1, 0)
        scrollToPage(previousPage)
    }
    
    // 获取当前页面索引
    func getCurrentPageIndex() -> Int {
        return currentIndex
    }
}

// MARK: - 使用示例
/*
使用方法：

1. 在 Storyboard 中添加 UITableView 并连接 IBOutlet
2. 或者纯代码创建：

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pagingVC = PagingTableViewController()
        addChild(pagingVC)
        view.addSubview(pagingVC.view)
        pagingVC.view.frame = view.bounds
        pagingVC.didMove(toParent: self)
    }
}

3. 主要特性：
- 每个 cell 占据全屏高度
- 手动滑动时会自动对齐到最近的页面
- 支持快速滑动和慢速滑动的不同处理逻辑
- 提供程序控制滚动的方法
- 可以自定义滑动灵敏度和切换阈值

*/
