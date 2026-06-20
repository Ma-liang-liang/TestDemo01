//
//  AlgorithmViewModel+LinkedList.swift
//  TestDemo
//
//  算法分类：链表
//  本文件包含 2 道链表类型的经典面试题
//

import Foundation

// MARK: - 链表节点定义
class ListNode {
    var val: Int
    var next: ListNode?
    
    init(_ val: Int, _ next: ListNode? = nil) {
        self.val = val
        self.next = next
    }
    
    /// 从数组构建链表
    static func from(_ arr: [Int]) -> ListNode? {
        guard !arr.isEmpty else { return nil }
        let head = ListNode(arr[0])
        var current = head
        for i in 1..<arr.count {
            current.next = ListNode(arr[i])
            current = current.next!
        }
        return head
    }
    
    /// 链表转数组（用于结果展示）
    func toArray() -> [Int] {
        var result = [Int]()
        var current: ListNode? = self
        while let node = current {
            result.append(node.val)
            current = node.next
        }
        return result
    }
}

extension AlgorithmViewModel {
    
    // MARK: - 题目 003：反转链表（Reverse Linked List）
    ///
    /// **题意**：给你单链表的头节点 head，请你反转链表，并返回反转后的链表。
    ///
    /// **示例**：
    /// - 输入：head = [1, 2, 3, 4, 5]
    /// - 输出：[5, 4, 3, 2, 1]
    ///
    /// **思路讲解**：
    /// - 迭代法：用三个指针 prev、curr、next 逐步翻转每个节点的指向
    ///   - prev 记录前一个节点（初始为 nil）
    ///   - curr 记录当前节点（初始为 head）
    ///   - 每次先把 curr.next 暂存到 next，然后把 curr.next 指向 prev，
    ///     再整体前移 prev = curr、curr = next
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：指针操作、边界处理（空链表、单节点）
    ///
    static func reverseList(_ head: ListNode?) -> ListNode? {
        var prev: ListNode? = nil
        var curr = head
        while curr != nil {
            let next = curr?.next   // 暂存下一个节点
            curr?.next = prev        // 翻转指向
            prev = curr              // prev 前移
            curr = next              // curr 前移
        }
        return prev
    }
    
    // MARK: - 题目 004：合并两个有序链表（Merge Two Sorted Lists）
    ///
    /// **题意**：将两个升序链表合并为一个新的升序链表并返回。
    /// 新链表是通过拼接给定的两个链表的所有节点组成的。
    ///
    /// **示例**：
    /// - 输入：l1 = [1, 2, 4]，l2 = [1, 3, 4]
    /// - 输出：[1, 1, 2, 3, 4, 4]
    ///
    /// **思路讲解**：
    /// - 哨兵节点 + 双指针：
    ///   - 创建虚拟头节点 dummy，用 tail 指针追踪合并链表的尾部
    ///   - 比较 l1 和 l2 的当前值，将较小的那个接到 tail 后面
    ///   - 某个链表遍历完后，把另一个链表剩余部分直接接到尾部
    /// - 时间 O(n+m)，空间 O(1)
    ///
    /// **面试考点**：哨兵节点技巧、双链表同步遍历
    ///
    static func mergeTwoLists(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
        let dummy = ListNode(0)     // 哨兵节点
        var tail: ListNode? = dummy
        var p1 = l1
        var p2 = l2
        
        while let n1 = p1, let n2 = p2 {
            if n1.val <= n2.val {
                tail?.next = n1
                p1 = n1.next
            } else {
                tail?.next = n2
                p2 = n2.next
            }
            tail = tail?.next
        }
        // 接上剩余部分
        tail?.next = p1 ?? p2
        return dummy.next
    }
}

// MARK: - 链表类题目注册
extension AlgorithmViewModel {
    
    var linkedListProblems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 3,
                title: "反转链表 (Reverse Linked List)",
                difficulty: .easy,
                category: .linkedList,
                description: """
                    给你单链表的头节点 head，反转链表并返回反转后的链表。
                    
                    示例：head = [1, 2, 3, 4, 5]
                    输出：[5, 4, 3, 2, 1]
                """,
                explanation: """
                    【核心思路】迭代三指针法：
                    
                    1. prev = nil（反转后的头）
                    2. curr = head（当前遍历节点）
                    3. 循环中：
                       - next = curr.next  （暂存下一个节点）
                       - curr.next = prev  （翻转指向）
                       - prev = curr       （prev 前移）
                       - curr = next       （curr 前移）
                    4. 循环结束，prev 就是新的头
                    
                    时间复杂度：O(n) —— 遍历一次
                    空间复杂度：O(1) —— 只用了几个指针变量
                    
                    【面试追问：递归怎么写？】
                    递归版：head.next.next = head; head.next = nil
                    从尾部开始，每层递归把当前节点接到下一层返回的链表尾部。
                    递归版空间 O(n)（调用栈），迭代版更优。
                """,
                solution: {
                    let head = ListNode.from([1, 2, 3, 4, 5])
                    let reversed = AlgorithmViewModel.reverseList(head)
                    let result = reversed?.toArray() ?? []
                    return """
                        输入：[1, 2, 3, 4, 5]
                        反转后：\(result)
                    """
                }
            ),
            AlgorithmProblem(
                id: 4,
                title: "合并两个有序链表",
                difficulty: .easy,
                category: .linkedList,
                description: """
                    将两个升序链表合并为一个新的升序链表。
                    
                    示例：l1 = [1, 2, 4]，l2 = [1, 3, 4]
                    输出：[1, 1, 2, 3, 4, 4]
                """,
                explanation: """
                    【核心思路】哨兵节点 + 双指针：
                    
                    1. 创建 dummy 节点（哨兵），tail 指向 dummy
                    2. p1 遍历 l1，p2 遍历 l2
                    3. 比较 p1.val 和 p2.val：
                       - 较小的接到 tail.next，对应指针前移
                       - tail = tail.next
                    4. 某链表遍历完后，tail.next = 剩余链表
                    5. 返回 dummy.next
                    
                    时间复杂度：O(n+m) —— 两个链表各遍历一次
                    空间复杂度：O(1) —— 只改指针，不创建新节点
                    
                    【为什么用哨兵节点？】
                    哨兵节点（dummy）避免了处理头节点为空的特殊情况，
                    让代码更统一简洁。这是链表题中非常常用的技巧，
                    面试中主动使用会给面试官留下好印象。
                """,
                solution: {
                    let l1 = ListNode.from([1, 2, 4])
                    let l2 = ListNode.from([1, 3, 4])
                    let merged = AlgorithmViewModel.mergeTwoLists(l1, l2)
                    let result = merged?.toArray() ?? []
                    return """
                        输入：l1 = [1, 2, 4]，l2 = [1, 3, 4]
                        合并后：\(result)
                    """
                }
            ),
        ]
    }
}
