//
//  AlgorithmViewModel+SlidingWindow.swift
//  TestDemo
//
//  算法分类：滑动窗口
//  本文件包含 2 道滑动窗口类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 019：无重复字符的最长子串（Longest Substring Without Repeating Characters）
    ///
    /// **题意**：给定一个字符串 s，请你找出其中不含有重复字符的最长子串的长度。
    ///
    /// **示例**：
    /// - 输入：s = "abcabcbb"
    /// - 输出：3（最长无重复子串是 "abc"）
    ///
    /// **思路讲解**：
    /// - 滑动窗口 + 哈希集合：
    ///   - 维护窗口 [left, right]，用 Set 记录窗口内的字符
    ///   - right 向右扩展，遇到重复字符时 left 右移并移除对应字符
    ///   - 每步更新最大窗口长度
    /// - 时间 O(n)，空间 O(min(n, m))（m 为字符集大小）
    ///
    /// **面试考点**：滑动窗口模板、窗口收缩条件的判断
    ///
    static func lengthOfLongestSubstring(_ s: String) -> Int {
        let chars = Array(s)
        var window = Set<Character>()
        var left = 0
        var maxLen = 0
        
        for right in 0..<chars.count {
            // 窗口内有重复字符 → 收缩左边界
            while window.contains(chars[right]) {
                window.remove(chars[left])
                left += 1
            }
            window.insert(chars[right])
            maxLen = max(maxLen, right - left + 1)
        }
        return maxLen
    }
    
    // MARK: - 题目 020：长度最小的子数组（Minimum Size Subarray Sum）
    ///
    /// **题意**：给定一个含有 n 个正整数的数组和一个正整数 target，
    /// 找出满足其和 ≥ target 的长度最小的连续子数组，并返回其长度。
    /// 如果不存在符合条件的子数组，返回 0。
    ///
    /// **示例**：
    /// - 输入：target = 7, nums = [2, 3, 1, 2, 4, 3]
    /// - 输出：2（子数组 [4, 3] 的和 ≥ 7，长度最小为 2）
    ///
    /// **思路讲解**：
    /// - 滑动窗口（右扩左缩）：
    ///   - right 向右扩展，累加窗口和
    ///   - 当窗口和 ≥ target 时，记录长度并收缩 left（窗口和减去 nums[left]）
    ///   - 持续收缩直到窗口和 < target
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：窗口扩展/收缩的时机、为什么不是双指针的"对撞"
    ///
    static func minSubArrayLen(_ target: Int, _ nums: [Int]) -> Int {
        var left = 0
        var sum = 0
        var minLen = Int.max
        
        for right in 0..<nums.count {
            sum += nums[right]
            // 窗口和满足条件 → 尝试收缩
            while sum >= target {
                minLen = min(minLen, right - left + 1)
                sum -= nums[left]
                left += 1
            }
        }
        return minLen == Int.max ? 0 : minLen
    }
}

// MARK: - 滑动窗口类题目注册
extension AlgorithmViewModel {
    
    var slidingWindowProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 19,
                title: "无重复字符的最长子串",
                difficulty: .medium,
                category: .slidingWindow,
                description: """
                    找出字符串中不含重复字符的最长子串的长度。
                    
                    示例：s = "abcabcbb"
                    输出：3（"abc"）
                """,
                explanation: """
                    【核心思路】滑动窗口 + 哈希集合：
                    
                    1. 维护窗口 [left, right]，Set 记录窗口内的字符
                    2. right 从 0 开始遍历：
                       - 如果 chars[right] 已在 Set 中：
                         循环移除 chars[left] 并 left++，直到不重复
                       - 将 chars[right] 加入 Set
                       - 更新 maxLen = max(maxLen, right - left + 1)
                    3. 返回 maxLen
                    
                    时间复杂度：O(n) —— 每个字符最多进出窗口各一次
                    空间复杂度：O(min(n, m)) —— m 为字符集大小
                    
                    【面试追问：能否用字典优化？】
                    用字典 [Character: Int] 记录字符最后一次出现的位置。
                    遇到重复字符时，直接 left = max(left, lastSeen[char] + 1)，
                    跳过中间不需要逐个移动的步骤，但时间复杂度仍为 O(n)。
                    
                    【滑动窗口模板总结】
                    1. 右指针扩展窗口
                    2. 不满足条件时收缩左指针
                    3. 每次更新答案（在扩展后或收缩后，取决于题目）
                """,
                solution: {
                    let tests = [("abcabcbb", 3), ("bbbbb", 1), ("pwwkew", 3), ("", 0)]
                    let results = tests.map { s, expected in
                        let result = AlgorithmViewModel.lengthOfLongestSubstring(s)
                        return "\"\(s)\" → \(result)（期望 \(expected)）"
                    }
                    return results.joined(separator: "\n")
                }
            ),
            AlgorithmProblem(
                id: 20,
                title: "长度最小的子数组",
                difficulty: .medium,
                category: .slidingWindow,
                description: """
                    找出和 ≥ target 的长度最小的连续子数组，返回其长度。
                    
                    示例：target = 7, nums = [2, 3, 1, 2, 4, 3]
                    输出：2（子数组 [4, 3]）
                """,
                explanation: """
                    【核心思路】滑动窗口（先扩后缩）：
                    
                    1. sum = 0, left = 0, minLen = ∞
                    2. right 遍历数组，sum += nums[right]
                    3. while sum >= target：
                       - minLen = min(minLen, right - left + 1)
                       - sum -= nums[left]
                       - left++
                    4. 返回 minLen == ∞ ? 0 : minLen
                    
                    时间复杂度：O(n) —— 每个元素最多进出窗口各一次
                    空间复杂度：O(1)
                    
                    【为什么滑动窗口能用？】
                    因为数组全是正整数！窗口和随 right 扩展单调递增，
                    随 left 收缩单调递减。这个单调性保证了：
                    一旦 sum < target，就不需要再收缩了。
                    
                    【面试追问：如果有负数呢？】
                    有负数时窗口和不再单调，滑动窗口失效。
                    需要用前缀和 + 二分查找，时间 O(nlogn)。
                    面试中要主动说明"正整数"是滑动窗口可用的前提。
                    
                    【面试追问：O(nlogn) 怎么写？】
                    计算前缀和数组 sums，对每个 left，
                    用二分查找找到最小的 right 使得 sums[right] - sums[left] >= target。
                """,
                solution: {
                    let target1 = 7
                    let nums1 = [2, 3, 1, 2, 4, 3]
                    let r1 = AlgorithmViewModel.minSubArrayLen(target1, nums1)
                    let target2 = 11
                    let nums2 = [1, 1, 1, 1, 1, 1, 1, 1]
                    let r2 = AlgorithmViewModel.minSubArrayLen(target2, nums2)
                    let target3 = 4
                    let nums3 = [1, 4, 4]
                    let r3 = AlgorithmViewModel.minSubArrayLen(target3, nums3)
                    return """
                        示例1：target=\(target1), nums=\(nums1) → \(r1)（子数组 [4,3]）
                        示例2：target=\(target2), nums=\(nums2) → \(r2)（总和不足，返回 0）
                        示例3：target=\(target3), nums=\(nums3) → \(r3)（子数组 [4]）
                    """
                }
            ),
        ]
    }
}
