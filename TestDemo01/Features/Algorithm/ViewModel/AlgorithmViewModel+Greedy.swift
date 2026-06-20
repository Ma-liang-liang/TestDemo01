//
//  AlgorithmViewModel+Greedy.swift
//  TestDemo
//
//  算法分类：贪心
//  本文件包含 2 道贪心类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 015：分发饼干（Assign Cookies）
    ///
    /// **题意**：假设你是一位家长，想给孩子们分饼干。每个孩子 i 有一个贪心值 g[i]，
    /// 表示能让他满足的最小饼干尺寸。每块饼干 j 有一个尺寸 s[j]。
    /// 如果 s[j] >= g[i]，可以将饼干 j 分给孩子 i，该孩子得到满足。
    /// 目标是满足尽可能多的孩子，返回最大满足数量。
    ///
    /// **示例**：
    /// - 输入：g = [1, 2, 3], s = [1, 1]
    /// - 输出：1（只有 1 个孩子能被满足）
    ///
    /// **思路讲解**：
    /// - 贪心策略：排序 + 双指针
    ///   - 将孩子需求和饼干尺寸都升序排序
    ///   - 用最小的饼干去满足需求最小的孩子（局部最优）
    ///   - 能满足则两个指针都前进，不能满足则换更大的饼干
    /// - 时间 O(nlogn + mlogm)，空间 O(1)
    ///
    /// **面试考点**：贪心策略的证明、排序后双指针
    ///
    static func findContentChildren(_ g: [Int], _ s: [Int]) -> Int {
        let greed = g.sorted()
        let sizes = s.sorted()
        var child = 0
        var cookie = 0
        
        while child < greed.count && cookie < sizes.count {
            if sizes[cookie] >= greed[child] {
                child += 1  // 满足了一个孩子
            }
            cookie += 1     // 饼干不管够不够都要看下一块
        }
        return child
    }
    
    // MARK: - 题目 016：跳跃游戏（Jump Game）
    ///
    /// **题意**：给定一个非负整数数组 nums，你最初位于数组的第一个下标。
    /// 数组中的每个元素代表你在该位置可以跳跃的最大长度。
    /// 判断你是否能够到达最后一个下标。
    ///
    /// **示例**：
    /// - 输入：nums = [2, 3, 1, 1, 4] → 输出：true
    /// - 输入：nums = [3, 2, 1, 0, 4] → 输出：false
    ///
    /// **思路讲解**：
    /// - 贪心：维护「最远可达位置」
    ///   - 遍历数组，在每个位置 i，更新最远可达 = max(最远可达, i + nums[i])
    ///   - 如果当前 i > 最远可达，说明到不了这里，返回 false
    ///   - 如果最远可达 >= 最后一个下标，返回 true
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：贪心 vs DP、最远可达的思想
    ///
    static func canJump(_ nums: [Int]) -> Bool {
        var maxReach = 0
        
        for i in 0..<nums.count {
            if i > maxReach { return false }     // 到不了当前位置
            maxReach = max(maxReach, i + nums[i])
            if maxReach >= nums.count - 1 { return true }  // 已能到达终点
        }
        return true
    }
}

// MARK: - 贪心类题目注册
extension AlgorithmViewModel {
    
    var greedyProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 15,
                title: "分发饼干 (Assign Cookies)",
                difficulty: .easy,
                category: .greedy,
                description: """
                    给孩子分饼干，每个孩子有最小需求尺寸，
                    每块饼干有固定尺寸，求最多能满足几个孩子。
                    
                    示例：g = [1, 2, 3], s = [1, 1]
                    输出：1
                """,
                explanation: """
                    【核心思路】排序 + 贪心双指针：
                    
                    1. 将孩子需求 g 和饼干尺寸 s 都升序排序
                    2. 双指针：child 指向当前孩子，cookie 指向当前饼干
                    3. 如果 s[cookie] >= g[child]：
                       - 这块饼干够大，满足该孩子，child++
                    4. 无论是否满足，cookie++（这块饼干不能再用了）
                    5. 返回 child 即为满足的孩子数
                    
                    时间复杂度：O(nlogn + mlogm) —— 排序
                    空间复杂度：O(1)
                    
                    【为什么贪心是对的？】
                    用最小的饼干去满足需求最小的孩子，是局部最优选择。
                    如果把大饼干给了小需求的孩子，那么大需求的孩子就
                    没有饼干可用了。所以"小的配小的"才能保证整体最优。
                    
                    【面试追问：如果每个孩子最多分 2 块饼干呢？】
                    问题变为背包/分配问题，贪心不再适用，需要 DP。
                    面试中要能识别贪心失效的场景。
                """,
                solution: {
                    let g1 = [1, 2, 3]
                    let s1 = [1, 1]
                    let r1 = AlgorithmViewModel.findContentChildren(g1, s1)
                    let g2 = [1, 2]
                    let s2 = [1, 2, 3]
                    let r2 = AlgorithmViewModel.findContentChildren(g2, s2)
                    return """
                        示例1：g=\(g1), s=\(s1) → 满足 \(r1) 个孩子
                        示例2：g=\(g2), s=\(s2) → 满足 \(r2) 个孩子
                    """
                }
            ),
            AlgorithmProblem(
                id: 16,
                title: "跳跃游戏 (Jump Game)",
                difficulty: .medium,
                category: .greedy,
                description: """
                    给定非负整数数组，每个元素代表该位置能跳的最大长度，
                    判断能否到达最后一个下标。
                    
                    示例1：nums = [2, 3, 1, 1, 4] → true
                    示例2：nums = [3, 2, 1, 0, 4] → false
                """,
                explanation: """
                    【核心思路】贪心 —— 维护最远可达位置：
                    
                    1. maxReach = 0（初始能到达的最远位置）
                    2. 遍历每个位置 i：
                       - 如果 i > maxReach → 到不了这里，返回 false
                       - maxReach = max(maxReach, i + nums[i])
                       - 如果 maxReach >= 最后下标 → 返回 true
                    3. 遍历结束返回 true
                    
                    时间复杂度：O(n) —— 一次遍历
                    空间复杂度：O(1)
                    
                    【为什么贪心是对的？】
                    我们只关心"最远能到哪里"，不关心具体跳到哪个位置。
                    因为在位置 i 能跳到 i+1, i+2, ..., i+nums[i] 中的任意一个，
                    所以维护最远可达就是全局最优信息。
                    
                    【面试追问：求最少跳跃次数呢？（Jump Game II）】
                    仍然是贪心，但需要维护「当前跳跃的边界」和「下一步最远可达」：
                    - 遍历数组（不含最后），更新 nextMaxReach
                    - 当 i == currentEnd 时，跳跃次数 +1，currentEnd = nextMaxReach
                    时间 O(n)，空间 O(1)。
                """,
                solution: {
                    let nums1 = [2, 3, 1, 1, 4]
                    let r1 = AlgorithmViewModel.canJump(nums1)
                    let nums2 = [3, 2, 1, 0, 4]
                    let r2 = AlgorithmViewModel.canJump(nums2)
                    let nums3 = [0]
                    let r3 = AlgorithmViewModel.canJump(nums3)
                    return """
                        示例1：\(nums1) → \(r1)
                        示例2：\(nums2) → \(r2)
                        示例3：\(nums3) → \(r3)（单个元素，已在终点）
                    """
                }
            ),
        ]
    }
}
