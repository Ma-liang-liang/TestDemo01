//
//  AlgorithmViewModel+Array.swift
//  TestDemo
//
//  算法分类：数组
//  本文件包含 2 道数组类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 001：两数之和（Two Sum）
    ///
    /// **题意**：给定一个整数数组 nums 和一个整数目标值 target，
    /// 请你在该数组中找出和为目标值 target 的那两个整数，并返回它们的数组下标。
    ///
    /// **示例**：
    /// - 输入：nums = [2, 7, 11, 15], target = 9
    /// - 输出：[0, 1]（因为 nums[0] + nums[7] == 9）
    ///
    /// **思路讲解**：
    /// - 暴力解法：双重循环遍历，时间 O(n²)，空间 O(1)
    /// - 最优解（哈希表）：遍历数组时，用字典记录「已遍历过的数字 → 下标」，
    ///   对于当前元素 nums[i]，检查字典中是否存在 target - nums[i]，
    ///   如果存在，直接返回两个下标。时间 O(n)，空间 O(n)
    ///
    /// **面试考点**：时间换空间的思维、字典的使用
    ///
    static func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
        var dict: [Int: Int] = [:] // key: 数字，value: 下标
        for (index, num) in nums.enumerated() {
            let complement = target - num
            if let matchIndex = dict[complement] {
                return [matchIndex, index]
            }
            dict[num] = index
        }
        return []
    }
    
    // MARK: - 题目 002：删除有序数组中的重复项（Remove Duplicates from Sorted Array）
    ///
    /// **题意**：给你一个非严格递增排列的数组 nums，请你原地删除重复出现的元素，
    /// 使每个元素只出现一次，返回删除后数组的新长度。
    ///
    /// **示例**：
    /// - 输入：nums = [0, 0, 1, 1, 2]
    /// - 输出：3，前三个元素变为 [0, 1, 2]
    ///
    /// **思路讲解**：
    /// - 使用双指针（快慢指针）：
    ///   - 慢指针 slow 指向当前要写入的位置
    ///   - 快指针 fast 遍历整个数组
    ///   - 当 nums[fast] != nums[slow] 时，说明遇到了新的不重复元素，slow += 1 并赋值
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：双指针技巧、原地修改数组
    ///
    static func removeDuplicates(_ nums: inout [Int]) -> Int {
        guard !nums.isEmpty else { return 0 }
        var slow = 0
        for fast in 1..<nums.count {
            if nums[fast] != nums[slow] {
                slow += 1
                nums[slow] = nums[fast]
            }
        }
        return slow + 1
    }
}

// MARK: - 数组类题目注册
extension AlgorithmViewModel {
    
    var arrayProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 1,
                title: "两数之和 (Two Sum)",
                difficulty: .easy,
                category: .array,
                description: """
                    给定一个整数数组 nums 和一个整数目标值 target，
                    找出数组中和为目标值的两个整数的下标。
                    
                    示例：nums = [2, 7, 11, 15], target = 9
                    输出：[0, 1]
                """,
                explanation: """
                    【核心思路】使用哈希表（字典），一次遍历完成：
                    
                    1. 创建空字典 dict: [Int: Int]，存储「数字 → 下标」
                    2. 遍历数组，对于 nums[i]：
                       - 计算差值 complement = target - nums[i]
                       - 若 dict[complement] 存在，说明找到了配对，返回 [dict[complement], i]
                       - 否则将 nums[i] → i 存入字典
                    3. 遍历结束未找到则返回空数组
                    
                    时间复杂度：O(n) —— 只需遍历一次
                    空间复杂度：O(n) —— 字典最多存 n 个元素
                    
                    【为什么不用双重循环？】
                    暴力解法 O(n²) 在大数据量时会超时，哈希表将查找差值的操作
                    从 O(n) 降到了 O(1)，是典型的"空间换时间"思想。
                """,
                solution: {
                    let nums = [2, 7, 11, 15]
                    let target = 9
                    let result = AlgorithmViewModel.twoSum(nums, target)
                    return """
                        输入：nums = \(nums), target = \(target)
                        输出：\(result)
                        验证：nums[\(result[0])] + nums[\(result[1])] = \(nums[result[0]]) + \(nums[result[1]]) = \(nums[result[0]] + nums[result[1]])
                    """
                }
            ),
            AlgorithmProblem(
                id: 2,
                title: "删除有序数组中的重复项",
                difficulty: .easy,
                category: .array,
                description: """
                    给定一个非严格递增排列的数组 nums，
                    原地删除重复元素，返回新长度。
                    
                    示例：nums = [0, 0, 1, 1, 2]
                    输出：3，前三个元素为 [0, 1, 2]
                """,
                explanation: """
                    【核心思路】双指针（快慢指针）：
                    
                    1. 定义慢指针 slow = 0（指向当前要写入的位置）
                    2. 快指针 fast 从 1 开始遍历：
                       - 若 nums[fast] != nums[slow]，说明遇到新元素：
                         slow += 1，nums[slow] = nums[fast]
                       - 若相等，fast 继续前进（跳过重复元素）
                    3. 返回 slow + 1 即为新长度
                    
                    时间复杂度：O(n) —— 快指针遍历一次
                    空间复杂度：O(1) —— 原地修改
                    
                    【为什么用双指针？】
                    题目要求原地修改，不能创建新数组。双指针是处理
                    "原地去重/修改"类问题的通用技巧，慢指针负责写入，
                    快指针负责扫描，各司其职。
                """,
                solution: {
                    var nums = [0, 0, 1, 1, 2]
                    let newLength = AlgorithmViewModel.removeDuplicates(&nums)
                    let result = Array(nums.prefix(newLength))
                    return """
                        输入：[0, 0, 1, 1, 2]
                        新长度：\(newLength)
                        去重后前 \(newLength) 个元素：\(result)
                    """
                }
            ),
        ]
    }
}
