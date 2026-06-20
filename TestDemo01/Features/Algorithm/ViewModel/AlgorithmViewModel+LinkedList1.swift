//
//  AlgorithmViewModel+LinkedList1.swift
//  TestDemo
//
//  算法分类：链表
//  本文件包含 2 道链表类型的经典面试题（第二组）
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 021：环形链表（Linked List Cycle）
    ///
    /// **题意**：给你一个链表的头节点 head，判断链表中是否有环。
    /// 如果链表中存在环，则返回 true。
    ///
    /// **示例**：
    /// - 输入：head = [3, 2, 0, -4], pos = 1（尾节点连到第 1 个节点）
    /// - 输出：true
    ///
    /// **思路讲解**：
    /// - 快慢指针（Floyd 判圈算法）：
    ///   - 慢指针每次走 1 步，快指针每次走 2 步
    ///   - 如果有环，快指针一定会追上慢指针（两者相遇）
    ///   - 如果无环，快指针会先到达 null
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：快慢指针证明、为什么快指针步长是 2
    ///
    static func hasCycle(_ head: ListNode?) -> Bool {
        var slow = head
        var fast = head
        
        while fast != nil && fast?.next != nil {
            slow = slow?.next
            fast = fast?.next?.next
            if slow === fast { return true }  // 引用相同 → 有环
        }
        return false
    }
    
    // MARK: - 题目 022：删除链表的倒数第 N 个结点
    ///
    /// **题意**：给你一个链表，请你删除链表的倒数第 n 个结点，并返回链表的头结点。
    ///
    /// **示例**：
    /// - 输入：head = [1, 2, 3, 4, 5], n = 2
    /// - 输出：[1, 2, 3, 5]（删除倒数第 2 个节点 4）
    ///
    /// **思路讲解**：
    /// - 快慢指针（间隔 n 步）：
    ///   - 先让快指针走 n 步
    ///   - 然后快慢指针同时走，当快指针到达末尾时，慢指针就在倒数第 n+1 个
    ///   - 使用哨兵节点 dummy 避免删除头节点的特殊情况
    /// - 时间 O(n)，空间 O(1)
    ///
    /// **面试考点**：快慢指针间隔技巧、哨兵节点处理边界
    ///
    static func removeNthFromEnd(_ head: ListNode?, _ n: Int) -> ListNode? {
        let dummy = ListNode(0)
        dummy.next = head
        
        var fast: ListNode? = dummy
        var slow: ListNode? = dummy
        
        // 快指针先走 n+1 步（多一步是为了让 slow 停在待删节点的前一个）
        for _ in 0...n {
            fast = fast?.next
        }
        
        // 同时移动，直到 fast 到达末尾
        while fast != nil {
            slow = slow?.next
            fast = fast?.next
        }
        
        // 删除 slow 的下一个节点
        slow?.next = slow?.next?.next
        
        return dummy.next
    }
}

// MARK: - 链表类题目注册（第二组）
extension AlgorithmViewModel {
    
    var linkedList1Problems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: 21,
                title: "环形链表 (Linked List Cycle)",
                difficulty: .easy,
                category: .linkedList,
                description: """
                    判断链表中是否有环。
                    
                    示例：head = [3, 2, 0, -4]，尾节点指向第 1 个节点
                    输出：true
                """,
                explanation: """
                    【核心思路】快慢指针（Floyd 判圈算法）：
                    
                    1. slow 和 fast 都从 head 出发
                    2. slow 每次走 1 步，fast 每次走 2 步
                    3. 如果 fast 和 fast.next 不为 nil：
                       - slow === fast → 有环，返回 true
                       - 否则继续
                    4. fast 到达末尾 → 无环，返回 false
                    
                    时间复杂度：O(n)
                    空间复杂度：O(1) —— 只用了两个指针
                    
                    【为什么快指针一定能追上慢指针？】
                    如果有环，每走一步快慢指针的距离减少 1。
                    假设环长为 L，最坏情况下 fast 需要绕环追 slow，
                    总共走的步数不超过 n（节点数）。
                    
                    【面试追问：为什么快指针步长是 2 不是 3？】
                    步长 2 能保证每次距离减少 1，一定能相遇。
                    步长 3 时，距离可能从 2 变 1 再变 0...也可能从 1 变 -1（跳过了），
                    需要取模分析，逻辑更复杂。步长 2 是最简洁安全的选择。
                    
                    【面试追问：如何找环的入口节点？（Linked List Cycle II）】
                    相遇后，一个指针回到 head，两个指针都每次走 1 步，
                    再次相遇的位置就是环的入口。数学可证。
                """,
                solution: {
                    // 构造有环链表：1 → 2 → 3 → 4 → 2（环）
                    let node1 = ListNode(1)
                    let node2 = ListNode(2)
                    let node3 = ListNode(3)
                    let node4 = ListNode(4)
                    node1.next = node2
                    node2.next = node3
                    node3.next = node4
                    node4.next = node2  // 形成环
                    
                    let hasCycleResult = AlgorithmViewModel.hasCycle(node1)
                    
                    // 构造无环链表：1 → 2 → 3
                    let noCycle = ListNode.from([1, 2, 3])
                    let noCycleResult = AlgorithmViewModel.hasCycle(noCycle)
                    
                    return """
                        有环链表 [1→2→3→4→2] → \(hasCycleResult)
                        无环链表 [1→2→3]      → \(noCycleResult)
                    """
                }
            ),
            AlgorithmProblem(
                id: 22,
                title: "删除链表的倒数第 N 个结点",
                difficulty: .medium,
                category: .linkedList,
                description: """
                    删除链表的倒数第 n 个结点，返回头节点。
                    
                    示例：head = [1, 2, 3, 4, 5], n = 2
                    输出：[1, 2, 3, 5]
                """,
                explanation: """
                    【核心思路】快慢指针（间隔 n 步）+ 哨兵节点：
                    
                    1. 创建 dummy 节点，dummy.next = head
                    2. fast 和 slow 都指向 dummy
                    3. fast 先走 n+1 步
                       （+1 是为了让 slow 最终停在「待删节点的前一个」）
                    4. fast 和 slow 同时走，直到 fast 到达末尾
                    5. slow.next = slow.next.next（删除目标节点）
                    6. 返回 dummy.next
                    
                    时间复杂度：O(n) —— 遍历一次
                    空间复杂度：O(1)
                    
                    【为什么用哨兵节点？】
                    如果要删除的恰好是头节点（n = 链表长度），
                    没有 dummy 就需要特殊处理。dummy 让所有情况统一，
                    不需要写 if 判断。
                    
                    【面试追问：如何只用一次遍历？】
                    上面的解法就是"一次遍历"—— fast 先走 n 步后，
                    两者一起走到末尾，总共每个节点只访问一次。
                    这是面试中的标准答案。
                """,
                solution: {
                    let head1 = ListNode.from([1, 2, 3, 4, 5])
                    let result1 = AlgorithmViewModel.removeNthFromEnd(head1, 2)
                    let arr1 = result1?.toArray() ?? []
                    
                    let head2 = ListNode.from([1])
                    let result2 = AlgorithmViewModel.removeNthFromEnd(head2, 1)
                    let arr2 = result2?.toArray() ?? []
                    
                    let head3 = ListNode.from([1, 2])
                    let result3 = AlgorithmViewModel.removeNthFromEnd(head3, 1)
                    let arr3 = result3?.toArray() ?? []
                    
                    return """
                        示例1：[1,2,3,4,5] 删除倒数第 2 个 → \(arr1)
                        示例2：[1] 删除倒数第 1 个 → \(arr2)（空链表）
                        示例3：[1,2] 删除倒数第 1 个 → \(arr3)
                    """
                }
            ),
        ]
    }
}
