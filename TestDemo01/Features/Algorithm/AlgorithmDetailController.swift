//
//  AlgorithmDetailController.swift
//  TestDemo
//
//  算法学习 - 题目详情页
//  展示题目描述、思路讲解、代码运行结果
//

import UIKit
import SnapKit

class AlgorithmDetailController: SKBaseController {
    
    private let problem: AlgorithmProblem
    
    init(problem: AlgorithmProblem) {
        self.problem = problem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI 组件
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let difficultyBadge = UILabel()
    private let runButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private var resultCard: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navBar.titleLabel.text = "#\(problem.id) \(problem.title)"
        setupUI()
    }
    
    private func setupUI() {
        // ScrollView（紧贴导航栏下方）
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // 内容 Stack
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 32, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        // 题目标题 + 难度
        titleLabel.text = problem.title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        
        difficultyBadge.text = "\(problem.difficulty.emoji)  \(problem.difficulty.rawValue)  |  分类：\(problem.category.rawValue)"
        difficultyBadge.font = .systemFont(ofSize: 13, weight: .medium)
        difficultyBadge.textColor = .secondaryLabel
        
        // 题目描述区
        let descSection = makeSection(title: "📝 题目描述", content: problem.description)
        
        // 思路讲解区
        let explainSection = makeSection(title: "💡 思路讲解", content: problem.explanation)
        
        // 运行按钮
        runButton.setTitle("▶  运行算法", for: .normal)
        runButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        runButton.backgroundColor = .systemBlue
        runButton.setTitleColor(.white, for: .normal)
        runButton.setTitleColor(.lightGray, for: .highlighted)
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(onRun), for: .touchUpInside)
        runButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        // 运行结果区（初始隐藏）
        resultLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        resultLabel.textColor = .label
        resultLabel.numberOfLines = 0
        resultLabel.text = ""
        
        resultCard = UIView()
        resultCard.backgroundColor = UIColor.systemGray6
        resultCard.layer.cornerRadius = 10
        resultCard.isHidden = true
        resultCard.addSubview(resultLabel)
        resultLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }
        
        // 组装
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(difficultyBadge)
        contentStack.addArrangedSubview(descSection)
        contentStack.addArrangedSubview(explainSection)
        contentStack.addArrangedSubview(runButton)
        contentStack.addArrangedSubview(resultCard)
    }
    
    // MARK: - 创建分区视图
    private func makeSection(title: String, content: String) -> UIView {
        let container = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let sectionTitle = UILabel()
        sectionTitle.text = title
        sectionTitle.font = .systemFont(ofSize: 17, weight: .semibold)
        sectionTitle.textColor = .label
        stack.addArrangedSubview(sectionTitle)
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 0
        stack.addArrangedSubview(contentLabel)
        
        return container
    }
    
    // MARK: - 事件
    @objc private func onRun() {
        let result = problem.solution()
        resultLabel.text = result
        resultCard.isHidden = false
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.runButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.runButton.transform = .identity
            }
        }
    }
}
