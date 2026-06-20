//
//  AlgorithmListController.swift
//  TestDemo
//
//  算法学习 - 题目列表页
//  按分类展示所有算法题，点击跳转到详情页
//

import UIKit

class AlgorithmListController: SKBaseController {
    
    private let viewModel = AlgorithmViewModel()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    /// 分组数据（懒加载，避免重复计算）
    private lazy var sections: [(category: AlgorithmProblem.Category, problems: [AlgorithmProblem])] = {
        viewModel.groupedProblems()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.titleLabel.text = "算法练习"
        setupUI()
    }
    
    private func setupUI() {
        let subtitleLabel = UILabel()
        subtitleLabel.text = "每周两题 · 备战iOS面试 · Swift实现"
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        // 列表
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "algoCell")
        tableView.backgroundColor = .systemGroupedBackground
        tableView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AlgorithmListController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].problems.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let category = sections[section].category
        return "\(category.rawValue)（\(sections[section].problems.count) 题）"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "algoCell", for: indexPath)
        let problem = sections[indexPath.section].problems[indexPath.row]
        
        cell.textLabel?.text = "\(problem.difficulty.emoji)  #\(problem.id)  \(problem.title)"
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let problem = sections[indexPath.section].problems[indexPath.row]
        let detailVC = AlgorithmDetailController(problem: problem)
        CGNavigationManager.shared.push(detailVC, stackId: .uikit)
    }
}
