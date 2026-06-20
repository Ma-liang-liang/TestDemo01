//
//  AlgorithmViewModel+Tree.swift
//  TestDemo
//
//  算法分类：二叉树
//  本文件包含 2 道二叉树类型的经典面试题
//

import Foundation

// MARK: - 二叉树节点定义
class TreeNode {
    var val: Int
    var left: TreeNode?
    var right: TreeNode?
    
    init(_ val: Int, _ left: TreeNode? = nil, _ right: TreeNode? = nil) {
        self.val = val
        self.left = left
        self.right = right
    }
    
    /// 层序遍历转数组（用于结果展示，nil 用 NSNull 占位）
    func levelOrderArray() -> [Any] {
        var result: [Any] = []
        var queue: [TreeNode?] = [self]
        while !queue.isEmpty {
            let node = queue.removeFirst()
            if let node = node {
                result.append(node.val)
                queue.append(node.left)
                queue.append(node.right)
            } else {
                result.append(NSNull())
            }
        }
        // 去掉末尾多余的 null
        while let last = result.last, last is NSNull {
            result.removeLast()
        }
        return result
    }
}

extension AlgorithmViewModel {
    
    // MARK: - 题目 005：二叉树的最大深度（Maximum Depth of Binary Tree）
    ///
    /// **题意**：给定一个二叉树 root，返回其最大深度。
    /// 最大深度是从根节点到最远叶子节点的最长路径上的节点数。
    ///
    /// **示例**：
    /// - 输入：root = [3, 9, 20, nil, nil, 15, 7]
    /// - 输出：3
    ///
    /// **思路讲解**：
    /// - DFS 递归：
    ///   - 当前节点为 nil，深度为 0
    ///   - 递归求左子树深度 leftDepth、右子树深度 rightDepth
    ///   - 当前深度 = max(leftDepth, rightDepth) + 1
    /// - 时间 O(n)，空间 O(h)（h 为树高，最坏 O(n)）
    ///
    /// **面试考点**：递归思维、树的遍历基础
    ///
    static func maxDepth(_ root: TreeNode?) -> Int {
        guard let root = root else { return 0 }
        let leftDepth = maxDepth(root.left)
        let rightDepth = maxDepth(root.right)
        return max(leftDepth, rightDepth) + 1
    }
    
    // MARK: - 题目 006：翻转二叉树（Invert Binary Tree）
    ///
    /// **题意**：给你一棵二叉树的根节点 root，翻转这棵二叉树，并返回翻转后的根节点。
    /// 翻转即交换每个节点的左右子树。
    ///
    /// **示例**：
    /// - 输入：root = [4, 2, 7, 1, 3, 6, 9]
    /// - 输出：[4, 7, 2, 9, 6, 3, 1]
    ///
    /// **思路讲解**：
    /// - 递归法（前序遍历）：
    ///   - 交换当前节点的左右子树
    ///   - 递归翻转左子树
    ///   - 递归翻转右子树
    /// - 也可以用 BFS 层序遍历，逐层交换每个节点的左右子节点
    /// - 时间 O(n)，空间 O(h)
    ///
    /// **面试考点**：递归 vs 迭代、树的遍历顺序
    ///
    static func invertTree(_ root: TreeNode?) -> TreeNode? {
        guard let root = root else { return nil }
        // 交换左右子树
        let temp = root.left
        root.left = invertTree(root.right)
        root.right = invertTree(temp)
        return root
    }
}

// MARK: - 二叉树类题目注册
extension AlgorithmViewModel {
    
    var treeProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 5,
                title: "二叉树的最大深度",
                difficulty: .easy,
                category: .tree,
                description: """
                    给定一个二叉树 root，返回其最大深度。
                    最大深度 = 根节点到最远叶子节点的最长路径上的节点数。
                    
                    示例：root = [3, 9, 20, nil, nil, 15, 7]
                    输出：3
                """,
                explanation: """
                    【核心思路】DFS 递归（自底向上）：
                    
                    1. 递归终止条件：节点为 nil，返回 0
                    2. 递归求左子树深度 leftDepth
                    3. 递归求右子树深度 rightDepth
                    4. 当前深度 = max(leftDepth, rightDepth) + 1
                    
                    时间复杂度：O(n) —— 每个节点访问一次
                    空间复杂度：O(h) —— 递归栈深度 = 树高
                    
                    【面试追问：BFS 怎么写？】
                    用队列层序遍历，每遍历完一层 depth += 1。
                    队列每次存放当前层的所有节点，依次出队并把子节点入队。
                    BFS 版空间 O(w)，w 为最大层宽，通常比 DFS 栈更优。
                """,
                solution: {
                    //        3
                    //       / \
                    //      9  20
                    //        /  \
                    //       15   7
                    let root = TreeNode(3,
                        TreeNode(9),
                        TreeNode(20, TreeNode(15), TreeNode(7))
                    )
                    let depth = AlgorithmViewModel.maxDepth(root)
                    return """
                        树结构：[3, 9, 20, nil, nil, 15, 7]
                        最大深度：\(depth)
                    """
                }
            ),
            AlgorithmProblem(
                id: 6,
                title: "翻转二叉树 (Invert Binary Tree)",
                difficulty: .easy,
                category: .tree,
                description: """
                    翻转一棵二叉树（交换每个节点的左右子树），
                    返回翻转后的根节点。
                    
                    示例：root = [4, 2, 7, 1, 3, 6, 9]
                    输出：[4, 7, 2, 9, 6, 3, 1]
                """,
                explanation: """
                    【核心思路】递归前序遍历：
                    
                    1. 当前节点为 nil，返回 nil
                    2. 交换当前节点的左右子树
                    3. 递归翻转左子树
                    4. 递归翻转右子树
                    5. 返回 root
                    
                    时间复杂度：O(n) —— 每个节点处理一次
                    空间复杂度：O(h) —— 递归栈
                    
                    【面试追问：迭代版怎么写？】
                    BFS 层序遍历：用队列存放节点，每次出队时交换该节点的
                    左右子节点，然后把左右子节点入队。这样逐层翻转，
                    不依赖递归栈，空间 O(w)。
                    
                    注意：翻转和镜像是同一道题，面试中可能换个说法出现。
                """,
                solution: {
                    //        4                 4
                    //       / \      =>       / \
                    //      2   7             7   2
                    //     /\  /\           /\  /\
                    //    1  3 6  9        9  6 3  1
                    let root = TreeNode(4,
                        TreeNode(2, TreeNode(1), TreeNode(3)),
                        TreeNode(7, TreeNode(6), TreeNode(9))
                    )
                    let inverted = AlgorithmViewModel.invertTree(root)
                    let result = inverted?.levelOrderArray() ?? []
                    return """
                        翻转前：[4, 2, 7, 1, 3, 6, 9]
                        翻转后：\(result)
                    """
                }
            ),
        ]
    }
}
