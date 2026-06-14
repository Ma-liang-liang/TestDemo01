//
//  SKAPIError.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit

public struct SKAPIError: Error, CustomStringConvertible {
    public let code: Int
    public let message: String
    public let data: [String: Any]?
    
    public init(code: Int, message: String, data: [String: Any]? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    public var description: String {
        """
        [SKAPI错误]
        代码: \(code)
        信息: \(message)
        数据: \(data ?? [:])
        """
    }
}
