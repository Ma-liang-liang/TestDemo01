//
//  AlgorithmViewModel+Stack.swift
//  TestDemo
//
//  算法分类：栈
//  本文件包含 2 道栈类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 013：有效的括号（Valid Parentheses）
    ///
    /// **题意**：给定一个只包括 '(', ')', '{', '}', '[', ']' 的字符串 s，
    /// 判断字符串是否有效。有效字符串需满足：
    /// 1. 左括号必须用相同类型的右括号闭合
    /// 2. 左括号必须以正确的顺序闭合
    /// 3. 每个右括号都有一个对应的相同类型的左括号
    ///
    /// **示例**：
    /// - 输入：s = "()[]{}"  → 输出：true
    /// - 输入：s = "(]"      → 输出：false
    ///
    /// **思路讲解**：
    /// - 用栈实现：
    ///   - 遇到左括号 → 入栈
    ///   - 遇到右括号 → 检查栈顶是否为对应的左括号，是则出栈，否则 false
    ///   - 遍历结束后栈为空 → true
    /// - 时间 O(n)，空间 O(n)
    ///
    /// **面试考点**：栈的 LIFO 特性、字典配对优化
    ///
    static func isValid(_ s: String) -> Bool {
        let pairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
        var stack: [Character] = []
        
        for char in s {
            if let match = pairs[char] {
                // 右括号：检查栈顶
                guard let top = stack.last, top == match else { return false }
                stack.removeLast()
            } else {
                // 左括号：入栈
                stack.append(char)
            }
        }
        return stack.isEmpty
    }
    
    // MARK: - 题目 014：最小栈（Min Stack）
    ///
    /// **题意**：设计一个支持 push、pop、top 操作，并能在常数时间内检索到最小元素的栈。
    /// - push(val)：将元素 val 推入栈中
    /// - pop()：移除栈顶元素
    /// - top()：获取栈顶元素
    /// - getMin()：获取栈中的最小元素
    ///
    /// **示例**：
    /// - 操作序列：push(-2), push(0), push(-3), getMin(), pop(), top(), getMin()
    /// - 输出：[-3, 0, -2]（getMin=-3, pop后top=0, getMin=-2）
    ///
    /// **思路讲解**：
    /// - 辅助栈（双栈法）：
    ///   - 主栈 dataStack 正常存储所有元素
    ///   - 辅助栈 minStack 存储「当前最小值」
    ///   - push 时：dataStack 正常入栈，minStack 入 min(val, minStack.top)
    ///   - pop 时：两个栈同时出栈
    ///   - getMin 时：直接读 minStack.top
    /// - 所有操作均为 O(1) 时间
    ///
    /// **面试考点**：空间换时间、辅助栈设计思路
    ///
    struct MinStack {
        private var dataStack: [Int] = []
        private var minStack: [Int] = []
        
        func isEmpty() -> Bool { dataStack.isEmpty }
        
        mutating func push(_ val: Int) {
            dataStack.append(val)
            let currentMin = minStack.isEmpty ? val : min(val, minStack.last!)
            minStack.append(currentMin)
        }
        
        mutating func pop() {
            guard !dataStack.isEmpty else { return }
            dataStack.removeLast()
            minStack.removeLast()
        }
        
        func top() -> Int? {
            dataStack.last
        }
        
        func getMin() -> Int? {
            minStack.last
        }
    }
}

// MARK: - 栈类题目注册
extension AlgorithmViewModel {
    
    var stackProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 13,
                title: "有效的括号 (Valid Parentheses)",
                difficulty: .easy,
                category: .stack,
                description: """
                    判断只包含括号的字符串是否有效。
                    左括号必须用相同类型的右括号按正确顺序闭合。
                    
                    示例1：s = "()[]{}"  → true
                    示例2：s = "(]"      → false
                """,
                explanation: """
                    【核心思路】栈 + 字典配对：
                    
                    1. 用字典建立右括号→左括号的映射：{")":"(", "]":"[", "}":"{"}
                    2. 遍历字符串每个字符：
                       - 遇到左括号 → 入栈
                       - 遇到右括号 → 检查栈顶是否为对应左括号
                         - 是 → 出栈，继续
                         - 否 → 返回 false
                    3. 遍历结束，栈为空 → true
                    
                    时间复杂度：O(n) —— 遍历一次
                    空间复杂度：O(n) —— 最坏全是左括号
                    
                    【面试追问：能用 O(1) 空间吗？】
                    不能，因为括号可能嵌套（如 "((()))"），
                    必须用栈记住未匹配的左括号。这是栈的经典应用场景，
                    面试中考的是能否快速识别出"后进先出"的模式。
                    
                    【常见错误】
                    忘记检查栈是否为空就直接取 last，会导致数组越界。
                """,
                solution: {
                    let tests = ["()", "()[]{}", "(]", "([)]", "{[]}", ""]
                    let results = tests.map { "\"\($0)\" → \(AlgorithmViewModel.isValid($0))" }
                    return """
                        测试结果：
                        \(results.joined(separator: "\n"))
                    """
                }
            ),
            AlgorithmProblem(
                id: 14,
                title: "最小栈 (Min Stack)",
                difficulty: .medium,
                category: .stack,
                description: """
                    设计一个栈，支持 push/pop/top 操作，
                    并能在 O(1) 时间内获取最小元素。
                    
                    示例操作：push(-2), push(0), push(-3), getMin()
                    输出：getMin=-3, pop后top=0, getMin=-2
                """,
                explanation: """
                    【核心思路】双栈法（辅助栈）：
                    
                    1. dataStack：正常存储所有元素
                    2. minStack：每个位置记录「到该位置为止的最小值」
                    3. push(val)：
                       - dataStack.append(val)
                       - minStack.append(min(val, minStack.last ?? val))
                    4. pop()：两个栈同时出栈
                    5. top()：dataStack.last
                    6. getMin()：minStack.last → O(1)
                    
                    时间复杂度：所有操作 O(1)
                    空间复杂度：O(n) —— 辅助栈
                    
                    【面试追问：能否不用辅助栈？】
                    可以用单个变量 minVal 记录最小值，但 pop 时如果
                    弹出的恰好是最小值，需要遍历整个栈重新找最小值 → O(n)。
                    辅助栈方案用 O(n) 空间换来了所有操作 O(1) 的时间，
                    这是面试中期望的标准解法。
                """,
                solution: {
                    var stack = AlgorithmViewModel.MinStack()
                    var log = ""
                    
                    stack.push(-2)
                    log += "push(-2)\n"
                    stack.push(0)
                    log += "push(0)\n"
                    stack.push(-3)
                    log += "push(-3)\n"
                    log += "getMin() → \(stack.getMin()!)\n"
                    stack.pop()
                    log += "pop()\n"
                    log += "top() → \(stack.top()!)\n"
                    log += "getMin() → \(stack.getMin()!)"
                    
                    return log
                }
            ),
        ]
    }
}
