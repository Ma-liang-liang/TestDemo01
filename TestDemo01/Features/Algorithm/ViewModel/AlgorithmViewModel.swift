//
//  AlgorithmViewModel.swift
//  TestDemo
//
//  算法学习模块 - 基础ViewModel
//  每周两道算法题，用Swift实现，配合讲解，备战iOS面试
//

import Foundation

// MARK: - 算法题目模型
struct AlgorithmProblem {
    let id: Int
    let title: String
    let difficulty: Difficulty
    let category: Category
    let description: String
    let explanation: String
    let solution: () -> String  // 运行并返回结果展示
    
    enum Difficulty: String {
        case easy = "简单"
        case medium = "中等"
        case hard = "困难"
        
        var emoji: String {
            switch self {
            case .easy: return "🟢"
            case .medium: return "🟡"
            case .hard: return "🔴"
            }
        }
    }
    
    enum Category: String, CaseIterable {
        case array = "数组"
        case string = "字符串"
        case linkedList = "链表"
        case tree = "树"
        case dynamicProgramming = "动态规划"
        case sort = "排序"
        case search = "搜索"
        case stack = "栈"
        case hashMap = "哈希表"
        case twoPointers = "双指针"
        case slidingWindow = "滑动窗口"
        case greedy = "贪心"
    }
}

// MARK: - 算法ViewModel
class AlgorithmViewModel {
    
    /// 所有算法题目（按分类组织）
    lazy var allProblems: [AlgorithmProblem] = {
        var problems = [AlgorithmProblem]()
        problems.append(contentsOf: arrayProblems)
        problems.append(contentsOf: stringProblems)
        problems.append(contentsOf: linkedListProblems)
        problems.append(contentsOf: linkedList1Problems)
        problems.append(contentsOf: treeProblems)
        problems.append(contentsOf: dynamicProgrammingProblems)
        problems.append(contentsOf: twoPointersProblems)
        problems.append(contentsOf: stackProblems)
        problems.append(contentsOf: greedyProblems)
        problems.append(contentsOf: sortProblems)
        problems.append(contentsOf: slidingWindowProblems)
        // 后续新增分类时在这里追加
        return problems
    }()
    
    /// 按分类分组
    func groupedProblems() -> [(category: AlgorithmProblem.Category, problems: [AlgorithmProblem])] {
        var dict: [AlgorithmProblem.Category: [AlgorithmProblem]] = [:]
        for problem in allProblems {
            dict[problem.category, default: []].append(problem)
        }
        // 按 Category 的 allCases 顺序排列
        return AlgorithmProblem.Category.allCases.compactMap { category in
            guard let problems = dict[category], !problems.isEmpty else { return nil }
            return (category: category, problems: problems)
        }
    }
    
    /// 根据 id 获取题目
    func problem(for id: Int) -> AlgorithmProblem? {
        allProblems.first { $0.id == id }
    }
}
