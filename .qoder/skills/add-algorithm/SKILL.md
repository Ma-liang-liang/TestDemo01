# add-algorithm

为算法练习模块新增 2 道同类型的算法题。

## 触发方式

```
/add-algorithm <算法分类>
```

示例：
- `/add-algorithm 字符串`
- `/add-algorithm 动态规划`
- `/add-algorithm 栈`
- `/add-algorithm add stack problems`

## 执行规则

### 1. 解析参数

从用户的自然语言中识别**算法分类**，映射到 `AlgorithmProblem.Category` 枚举值：

| 用户输入关键词 | Category 枚举值 | 枚举 rawValue |
|---|---|---|
| 数组 / array | `.array` | "数组" |
| 字符串 / string | `.string` | "字符串" |
| 链表 / linked list / linkedlist | `.linkedList` | "链表" |
| 树 / tree / 二叉树 | `.tree` | "树" |
| 动态规划 / dp | `.dynamicProgramming` | "动态规划" |
| 排序 / sort | `.sort` | "排序" |
| 搜索 / search / 二分 | `.search` | "搜索" |
| 栈 / stack | `.stack` | "栈" |
| 哈希 / hashmap / hash | `.hashMap` | "哈希表" |
| 双指针 / two pointers | `.twoPointers` | "双指针" |
| 滑动窗口 / sliding window | `.slidingWindow` | "滑动窗口" |
| 贪心 / greedy | `.greedy` | "贪心" |

如果无法识别，请询问用户。

### 2. 确定题目 ID

读取 `AlgorithmViewModel.swift` 中 `allProblems` 已注册的所有分类属性，找到当前最大的 `id`，新题 id = 最大 id + 1 和 + 2。

### 3. 检查分类是否已存在

检查 `TestDemo01/Features/Algorithm/ViewModel/` 目录下是否已有对应分类的文件：

- **文件不存在** → 新建文件，命名为 `AlgorithmViewModel+<PascalCaseName>.swift`
- **文件已存在** → 新建文件，在类型名后加数字后缀区分

命名规则（以链表为例）：
- 第 1 次：`AlgorithmViewModel+LinkedList.swift`
- 第 2 次：`AlgorithmViewModel+LinkedList1.swift`
- 第 3 次：`AlgorithmViewModel+LinkedList2.swift`
- 依此类推...

新文件的 var 命名也要加数字后缀：
- 第 1 次：`linkedListProblems`
- 第 2 次：`linkedList1Problems`
- 第 3 次：`linkedList2Problems`

**无论是否已存在，都始终创建新文件**（不追加到已有文件）。

### 4. 创建 extension 文件

**路径**: `TestDemo01/Features/Algorithm/ViewModel/AlgorithmViewModel+<PascalCaseName><Suffix>.swift`

基础命名映射（无后缀时）：
- 字符串 → `AlgorithmViewModel+String.swift`
- 动态规划 → `AlgorithmViewModel+DynamicProgramming.swift`
- 栈 → `AlgorithmViewModel+Stack.swift`
- 排序 → `AlgorithmViewModel+Sort.swift`
- 搜索 → `AlgorithmViewModel+Search.swift`
- 哈希表 → `AlgorithmViewModel+HashMap.swift`
- 双指针 → `AlgorithmViewModel+TwoPointers.swift`
- 滑动窗口 → `AlgorithmViewModel+SlidingWindow.swift`
- 贪心 → `AlgorithmViewModel+Greedy.swift`

**文件结构模板**（严格按此格式）：

```swift
//
//  AlgorithmViewModel+<PascalCaseName><Suffix>.swift
//  TestDemo
//
//  算法分类：<分类中文名>
//  本文件包含 2 道<分类中文名>类型的经典面试题
//

import Foundation

extension AlgorithmViewModel {
    
    // MARK: - 题目 <ID>：<中文题目标题>（<英文题目标题>）
    ///
    /// **题意**：<题目描述>
    ///
    /// **示例**：
    /// - 输入：<示例输入>
    /// - 输出：<示例输出>
    ///
    /// **思路讲解**：
    /// - <解题思路，分步骤说明>
    /// - 时间 O(?)，空间 O(?)
    ///
    /// **面试考点**：<面试中会考的核心点>
    ///
    static func <methodName>(<params>) -> <ReturnType> {
        // Swift 实现
    }
    
    // MARK: - 题目 <ID+1>：<第二题>
    /// ...（同上格式）
    static func <methodName2>(<params>) -> <ReturnType> {
        // Swift 实现
    }
}

// MARK: - <分类中文名>类题目注册
extension AlgorithmViewModel {
    
    var <categoryVarName><Suffix>Problems: [AlgorithmProblem] {
        [
            AlgorithmProblem(
                id: <ID>,
                title: "<题目中文名> (<英文名>)",
                difficulty: .easy 或 .medium,
                category: .<categoryEnum>,
                description: """
                    <题目描述 + 示例>
                """,
                explanation: """
                    【核心思路】<详细讲解，包含步骤、复杂度、面试追问>
                """,
                solution: {
                    // 构造测试数据，调用算法函数，返回结果字符串
                    return """
                        输入：<示例输入>
                        输出：<示例输出>
                    """
                }
            ),
            // ... 第二题同上格式
        ]
    }
}
```

### 5. 题目选取标准

- 难度：**简单(easy)** 或 **中等(medium)**，适合 iOS 面试
- 必须是 LeetCode 经典高频面试题
- 两题属于同一分类但考察不同技巧
- **不能与已有文件中同分类的题目重复**（先读取已有文件检查）
- 每题包含：算法实现 + 详细注释讲解 + 可运行的示例 + 面试追问点

### 6. 注册到 ViewModel

编辑 `TestDemo01/Features/Algorithm/ViewModel/AlgorithmViewModel.swift`，在 `allProblems` 的懒加载闭包中追加：

```swift
problems.append(contentsOf: <categoryVarName><Suffix>Problems)
```

添加在已有 `append` 语句之后、注释之前。

### 7. 注意事项

- 如果该分类需要自定义数据结构（如链表节点、树节点），先检查项目中是否已有定义（`ListNode`、`TreeNode`），有则复用，没有则在文件顶部新增
- 新文件中的算法函数名**不能**与同分类已有文件中的函数名重复
- `solution` 闭包中的代码必须可编译运行，确保引用正确的类型和方法
- 注释使用中文，代码使用英文命名
- 每道题都要有"面试追问"环节，展示更深入的思考（如迭代 vs 递归、优化方案等）
