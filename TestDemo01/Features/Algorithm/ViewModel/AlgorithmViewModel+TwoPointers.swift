//
//  AlgorithmViewModel+TwoPointers.swift
//  TestDemo
//
//  算法分类：双指针
//  本文件包含 2 道双指针类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 009：盛最多水的容器（Container With Most Water）
    ///
    /// **题意**：给定一个长度为 n 的整数数组 height，有 n 条垂线，
    /// 第 i 条线的两个端点是 (i, 0) 和 (i, height[i])。
    /// 找出其中的两条线，使得它们与 x 轴共同构成的容器可以容纳最多的水。
    ///
    /// **示例**：
    /// - 输入：height = [1, 8, 6, 2, 5, 4, 8, 3, 7]
    /// - 输出：49（选择下标 1 和 8，min(8,7) × 7 = 49）
    ///
    /// **思路讲解**：
    /// - 对撞双指针（左右向中间收拢）：
    ///   - left = 0，right = n-1
    ///   - 面积 = min(height[left], height[right]) × (right - left)
    ///   - 每次移动较矮的那一侧（因为移动高的那侧面积一定变小）
    ///   - 记录过程中的最大面积
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：贪心思想、为什么移动矮的一侧是正确的
    ///
    static func maxArea(_ height: [Int]) -> Int {
        var left = 0
        var right = height.count - 1
        var maxWater = 0
        
        while left < right {
            let water = min(height[left], height[right]) * (right - left)
            maxWater = max(maxWater, water)
            
            if height[left] < height[right] {
                left += 1
            } else {
                right -= 1
            }
        }
        return maxWater
    }
    
    // MARK: - 题目 010：验证回文串（Valid Palindrome）
    ///
    /// **题意**：给定一个字符串 s，在考虑大小写转换且忽略非字母数字字符的情况下，
    /// 判断该字符串是否为回文串。
    ///
    /// **示例**：
    /// - 输入：s = "A man, a plan, a canal: Panama"
    /// - 输出：true（忽略空格和标点，"amanaplanacanalpanama" 是回文）
    ///
    /// **思路讲解**：
    /// - 对撞双指针：
    ///   - left = 0，right = count - 1
    ///   - 跳过非字母数字字符
    ///   - 统一转小写后比较，不等则返回 false
    ///   - 全部匹配则返回 true
    /// - 时间 O(n)，空间 O(n)（转为字符数组）
    ///
    /// **面试考点**：字符过滤、isLetter / isNumber 的使用、边界处理
    ///
    static func isPalindrome(_ s: String) -> Bool {
        let chars = Array(s.lowercased())
        var left = 0
        var right = chars.count - 1
        
        while left < right {
            // 跳过非字母数字
            while left < right && !chars[left].isLetter && !chars[left].isNumber {
                left += 1
            }
            while left < right && !chars[right].isLetter && !chars[right].isNumber {
                right -= 1
            }
            if chars[left] != chars[right] {
                return false
            }
            left += 1
            right -= 1
        }
        return true
    }
}

// MARK: - 双指针类题目注册
extension AlgorithmViewModel {
    
    var twoPointersProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 9,
                title: "盛最多水的容器 (Container With Most Water)",
                difficulty: .medium,
                category: .twoPointers,
                description: """
                    给定整数数组 height，找出两条线使得它们构成的容器盛水最多。
                    
                    示例：height = [1, 8, 6, 2, 5, 4, 8, 3, 7]
                    输出：49
                """,
                explanation: """
                    【核心思路】对撞双指针 + 贪心：
                    
                    1. left = 0, right = n-1
                    2. 计算当前面积 = min(height[left], height[right]) × (right - left)
                    3. 更新 maxWater
                    4. 移动较矮的一侧：
                       - height[left] < height[right] → left++
                       - 否则 right--
                    5. 循环直到 left >= right
                    
                    时间复杂度：O(n) —— 两个指针各遍历一次
                    空间复杂度：O(1)
                    
                    【面试追问：为什么移动矮的一侧？】
                    面积由「短板」决定。假设 height[left] 更矮：
                    - 如果移动 right（高的一侧），宽度减小，高度不会变高，面积一定变小
                    - 移动 left（矮的一侧），宽度减小，但高度可能变高，面积有可能变大
                    所以只有移动矮的一侧才可能找到更大的面积。
                """,
                solution: {
                    let height = [1, 8, 6, 2, 5, 4, 8, 3, 7]
                    let result = AlgorithmViewModel.maxArea(height)
                    return """
                        输入：\(height)
                        最大盛水量：\(result)
                        解释：选择下标 1（高度 8）和下标 8（高度 7）
                        面积 = min(8, 7) × (8 - 1) = 7 × 7 = 49
                    """
                }
            ),
            AlgorithmProblem(
                id: 10,
                title: "验证回文串 (Valid Palindrome)",
                difficulty: .easy,
                category: .twoPointers,
                description: """
                    判断字符串是否为回文串（忽略非字母数字字符，不区分大小写）。
                    
                    示例：s = "A man, a plan, a canal: Panama"
                    输出：true
                """,
                explanation: """
                    【核心思路】对撞双指针 + 字符过滤：
                    
                    1. 转小写，转为字符数组
                    2. left = 0, right = count - 1
                    3. 循环中：
                       - left 跳过非字母数字字符
                       - right 跳过非字母数字字符
                       - 比较 chars[left] 和 chars[right]，不等则 false
                       - left++, right--
                    4. 全部匹配返回 true
                    
                    时间复杂度：O(n) —— 每个字符最多访问两次
                    空间复杂度：O(n) —— 字符数组
                    
                    【面试追问：能否 O(1) 空间？】
                    不预先转字符数组，直接在原字符串的 Index 上操作。
                    Swift 中 String 的 Index 操作稍繁琐但可行，
                    用 s.index(after:) 和 s.index(before:) 移动指针。
                    面试中先写出版本，再讨论优化方向即可。
                """,
                solution: {
                    let s1 = "A man, a plan, a canal: Panama"
                    let r1 = AlgorithmViewModel.isPalindrome(s1)
                    let s2 = "race a car"
                    let r2 = AlgorithmViewModel.isPalindrome(s2)
                    return """
                        示例1："\(s1)" → \(r1)
                        示例2："\(s2)" → \(r2)
                    """
                }
            ),
        ]
    }
}
