//
//  AlgorithmViewModel+String.swift
//  TestDemo
//
//  算法分类：字符串
//  本文件包含 2 道字符串类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 007：有效的字母异位词（Valid Anagram）
    ///
    /// **题意**：给定两个字符串 s 和 t，编写一个函数来判断 t 是否是 s 的字母异位词。
    /// 字母异位词指两个字符串包含的字符种类和数量完全相同，但顺序可以不同。
    ///
    /// **示例**：
    /// - 输入：s = "anagram", t = "nagaram"
    /// - 输出：true
    ///
    /// **思路讲解**：
    /// - 计数法（数组代替字典，更高效）：
    ///   - 如果长度不同，直接返回 false
    ///   - 用一个长度为 26 的数组记录每个字符出现的次数
    ///   - 遍历 s 时对应位置 +1，遍历 t 时对应位置 -1
    ///   - 最终数组所有元素都为 0 则是异位词
    /// - 时间 O(n)，空间 O(1)（固定 26 个字母）
    ///
    /// **面试考点**：字符计数、用数组代替字典优化性能
    ///
    static func isAnagram(_ s: String, _ t: String) -> Bool {
        guard s.count == t.count else { return false }
        var count = Array(repeating: 0, count: 26)
        let aValue = Character("a").asciiValue!
        
        let sChars = Array(s)
        let tChars = Array(t)
        for i in 0..<sChars.count {
            count[Int(sChars[i].asciiValue! - aValue)] += 1
            count[Int(tChars[i].asciiValue! - aValue)] -= 1
        }
        return count.allSatisfy { $0 == 0 }
    }
    
    // MARK: - 题目 008：最长公共前缀（Longest Common Prefix）
    ///
    /// **题意**：编写一个函数来查找字符串数组中的最长公共前缀。
    /// 如果不存在公共前缀，返回空字符串 ""。
    ///
    /// **示例**：
    /// - 输入：strs = ["flower", "flow", "flight"]
    /// - 输出："fl"
    ///
    /// **思路讲解**：
    /// - 纵向扫描法：
    ///   - 以第一个字符串为基准
    ///   - 从第 0 个字符开始，逐个与其余字符串对应位置比较
    ///   - 一旦遇到不匹配或某字符串已到头，返回当前前缀
    /// - 时间 O(S)，S 为所有字符串的字符总数；空间 O(1)
    ///
    /// **面试考点**：边界处理（空数组、单元素）、纵向 vs 横向扫描
    ///
    static func longestCommonPrefix(_ strs: [String]) -> String {
        guard let first = strs.first, !first.isEmpty else { return "" }
        let firstChars = Array(first)
        
        for i in 0..<firstChars.count {
            let char = firstChars[i]
            for j in 1..<strs.count {
                let chars = Array(strs[j])
                // 当前字符串已到头，或字符不匹配
                if i >= chars.count || chars[i] != char {
                    return String(firstChars.prefix(i))
                }
            }
        }
        return first
    }
}

// MARK: - 字符串类题目注册
extension AlgorithmViewModel {
    
    var stringProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 7,
                title: "有效的字母异位词 (Valid Anagram)",
                difficulty: .easy,
                category: .string,
                description: """
                    给定两个字符串 s 和 t，判断 t 是否是 s 的字母异位词。
                    字母异位词：字符种类和数量完全相同，顺序可以不同。
                    
                    示例：s = "anagram", t = "nagaram"
                    输出：true
                """,
                explanation: """
                    【核心思路】字符计数法：
                    
                    1. 长度不同 → 直接返回 false
                    2. 创建长度为 26 的计数数组（代替字典，更高效）
                    3. 同时遍历 s 和 t：
                       - s 的字符对应位置 +1
                       - t 的字符对应位置 -1
                    4. 检查数组是否全为 0
                    
                    时间复杂度：O(n) —— 遍历一次
                    空间复杂度：O(1) —— 固定 26 个字母的数组
                    
                    【面试追问：如果包含 Unicode 字符怎么办？】
                    不能再用 26 长度数组，需要改用字典 [Character: Int] 计数，
                    或者排序后比较：sorted(s) == sorted(t)，排序版时间 O(nlogn)。
                    面试中要主动询问字符范围，展现边界意识。
                """,
                solution: {
                    let s = "anagram"
                    let t = "nagaram"
                    let result = AlgorithmViewModel.isAnagram(s, t)
                    let s2 = "rat"
                    let t2 = "car"
                    let result2 = AlgorithmViewModel.isAnagram(s2, t2)
                    return """
                        示例1：s = "\(s)", t = "\(t)" → \(result)
                        示例2：s = "\(s2)", t = "\(t2)" → \(result2)
                    """
                }
            ),
            AlgorithmProblem(
                id: 8,
                title: "最长公共前缀 (Longest Common Prefix)",
                difficulty: .easy,
                category: .string,
                description: """
                    查找字符串数组中的最长公共前缀。
                    如果不存在公共前缀，返回 ""。
                    
                    示例：strs = ["flower", "flow", "flight"]
                    输出："fl"
                """,
                explanation: """
                    【核心思路】纵向扫描法：
                    
                    1. 以第一个字符串为基准
                    2. 从第 0 个字符开始，逐列比较：
                       - 取 first[i] 作为基准字符
                       - 与其余每个字符串的第 i 个字符比较
                       - 不匹配或某字符串已到末尾 → 返回 first[0..<i]
                    3. 全部匹配完 → 返回整个 first
                    
                    时间复杂度：O(S) —— S 为所有字符总数
                    空间复杂度：O(1)
                    
                    【面试追问：还有哪些方法？】
                    - 横向扫描：两两取公共前缀，依次合并
                    - 分治法：将数组分成两半，分别求公共前缀再合并
                    - 排序法：排序后只需比较首尾两个字符串
                    纵向扫描在大多数实际场景下最优，因为可以尽早提前返回。
                """,
                solution: {
                    let strs1 = ["flower", "flow", "flight"]
                    let result1 = AlgorithmViewModel.longestCommonPrefix(strs1)
                    let strs2 = ["dog", "racecar", "car"]
                    let result2 = AlgorithmViewModel.longestCommonPrefix(strs2)
                    return """
                        示例1：\(strs1) → "\(result1)"
                        示例2：\(strs2) → "\(result2)"
                    """
                }
            ),
        ]
    }
}
