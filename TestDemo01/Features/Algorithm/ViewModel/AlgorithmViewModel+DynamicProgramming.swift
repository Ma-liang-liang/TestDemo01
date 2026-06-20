//
//  AlgorithmViewModel+DynamicProgramming.swift
//  TestDemo
//
//  算法分类：动态规划
//  本文件包含 2 道动态规划类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 011：爬楼梯（Climbing Stairs）
    ///
    /// **题意**：假设你正在爬楼梯，需要 n 阶你才能到达楼顶。
    /// 每次你可以爬 1 或 2 个台阶。你有多少种不同的方法可以爬到楼顶？
    ///
    /// **示例**：
    /// - 输入：n = 3
    /// - 输出：3（方法：1+1+1、1+2、2+1）
    ///
    /// **思路讲解**：
    /// - 状态定义：dp[i] = 爬到第 i 阶的方法数
    /// - 状态转移：dp[i] = dp[i-1] + dp[i-2]
    ///   （到第 i 阶只能从第 i-1 阶爬 1 步，或从第 i-2 阶爬 2 步）
    /// - 初始条件：dp[1] = 1, dp[2] = 2
    /// - 空间优化：只需保存前两个值，不需要整个数组
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：DP 入门、状态转移方程推导、空间优化
    ///
    static func climbStairs(_ n: Int) -> Int {
        if n <= 2 { return n }
        var prev2 = 1  // dp[i-2]
        var prev1 = 2  // dp[i-1]
        for _ in 3...n {
            let curr = prev1 + prev2
            prev2 = prev1
            prev1 = curr
        }
        return prev1
    }
    
    // MARK: - 题目 012：打家劫舍（House Robber）
    ///
    /// **题意**：你是一个专业的小偷，计划偷窃沿街的房屋。每间房内都藏有一定的现金，
    /// 相邻的房屋装有相互连通的防盗系统，如果两间相邻的房屋在同一晚上被小偷闯入，
    /// 系统会自动报警。给定一个代表每个房屋存放金额的非负整数数组，
    /// 计算你不触动警报装置的情况下，一夜之内能够偷窃到的最高金额。
    ///
    /// **示例**：
    /// - 输入：nums = [2, 7, 9, 3, 1]
    /// - 输出：12（偷第 1、3、5 间：2 + 9 + 1 = 12）
    ///
    /// **思路讲解**：
    /// - 状态定义：dp[i] = 偷到第 i 间房屋的最大金额
    /// - 状态转移：dp[i] = max(dp[i-1], dp[i-2] + nums[i])
    ///   （第 i 间要么不偷 → dp[i-1]，要么偷 → dp[i-2] + nums[i]）
    /// - 初始条件：dp[0] = nums[0], dp[1] = max(nums[0], nums[1])
    /// - 空间优化：只需保存前两个值
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：选或不选型 DP、状态转移的推导逻辑
    ///
    static func rob(_ nums: [Int]) -> Int {
        guard !nums.isEmpty else { return 0 }
        if nums.count == 1 { return nums[0] }
        
        var prev2 = nums[0]                        // dp[i-2]
        var prev1 = max(nums[0], nums[1])           // dp[i-1]
        
        for i in 2..<nums.count {
            let curr = max(prev1, prev2 + nums[i])
            prev2 = prev1
            prev1 = curr
        }
        return prev1
    }
}

// MARK: - 动态规划类题目注册
extension AlgorithmViewModel {
    
    var dynamicProgrammingProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 11,
                title: "爬楼梯 (Climbing Stairs)",
                difficulty: .easy,
                category: .dynamicProgramming,
                description: """
                    爬 n 阶楼梯，每次可以爬 1 或 2 个台阶，
                    求有多少种不同的方法到达楼顶。
                    
                    示例：n = 3
                    输出：3（1+1+1、1+2、2+1）
                """,
                explanation: """
                    【核心思路】动态规划（斐波那契数列变体）：
                    
                    1. 到达第 n 阶只有两种方式：
                       - 从第 n-1 阶爬 1 步
                       - 从第 n-2 阶爬 2 步
                    2. 所以 dp[n] = dp[n-1] + dp[n-2]
                    3. 初始值：dp[1] = 1, dp[2] = 2
                    4. 空间优化：只保存 prev2 和 prev1 两个变量
                    
                    时间复杂度：O(n)
                    空间复杂度：O(1) —— 滚动变量优化
                    
                    【面试追问：能否进一步优化？】
                    - 矩阵快速幂：O(log n) 时间
                    - 通项公式（Binet公式）：O(1) 时间，但有浮点精度问题
                    面试中写出 O(n) 空间 O(1) 的版本即可，主动提及
                    矩阵快速幂会加分。关键是展示推导过程。
                """,
                solution: {
                    let results = [1, 2, 3, 4, 5, 6].map { ($0, AlgorithmViewModel.climbStairs($0)) }
                    let detail = results.map { "n=\($0.0) → \($0.1) 种" }.joined(separator: "\n")
                    return """
                        爬楼梯方法数：
                        \(detail)
                    """
                }
            ),
            AlgorithmProblem(
                id: 12,
                title: "打家劫舍 (House Robber)",
                difficulty: .medium,
                category: .dynamicProgramming,
                description: """
                    相邻房屋不能同时偷，求能偷到的最大金额。
                    
                    示例：nums = [2, 7, 9, 3, 1]
                    输出：12（偷第 1、3、5 间：2 + 9 + 1）
                """,
                explanation: """
                    【核心思路】选或不选型 DP：
                    
                    1. 对于第 i 间房屋，只有两个选择：
                       - 偷 → 第 i-1 间不能偷，总金额 = dp[i-2] + nums[i]
                       - 不偷 → 总金额 = dp[i-1]
                    2. dp[i] = max(dp[i-1], dp[i-2] + nums[i])
                    3. 初始值：dp[0] = nums[0], dp[1] = max(nums[0], nums[1])
                    4. 空间优化：只需 prev2 和 prev1
                    
                    时间复杂度：O(n)
                    空间复杂度：O(1)
                    
                    【面试追问：如果是环形排列呢？（House Robber II）】
                    首尾相连意味着第 0 间和最后一间不能同时偷。
                    拆成两个子问题：
                    - 偷范围 [0, n-2]（不偷最后一间）
                    - 偷范围 [1, n-1]（不偷第一间）
                    取两者的最大值。本质是把环形问题转化为两个线性问题。
                """,
                solution: {
                    let nums1 = [2, 7, 9, 3, 1]
                    let r1 = AlgorithmViewModel.rob(nums1)
                    let nums2 = [1, 2, 3, 1]
                    let r2 = AlgorithmViewModel.rob(nums2)
                    return """
                        示例1：\(nums1) → \(r1)（偷 2+9+1=12）
                        示例2：\(nums2) → \(r2)（偷 1+3=4）
                    """
                }
            ),
        ]
    }
}
