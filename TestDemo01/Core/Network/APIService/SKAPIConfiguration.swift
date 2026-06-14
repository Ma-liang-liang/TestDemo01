//
//  SKAPIConfiguration.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit

public final class SKAPIConfiguration {
    public static let shared = SKAPIConfiguration()
    
    // 基础配置
    public var baseURL: URL?
    public var commonHeaders: [String: String] = [:]
    public var commonParameters: [String: Any] = [:]
    public var timeoutInterval: TimeInterval = 30
    public var logEnabled: Bool = true
    
    // 新增拦截配置
    public var interceptCodes: Set<Int> = []
    public var interceptor: ((Int, String, [String: Any]) -> Bool)?
    
    private init() {}
    
    public func update(baseURL: URL? = nil,
                       headers: [String: String]? = nil,
                       parameters: [String: Any]? = nil) {
        self.baseURL = baseURL ?? self.baseURL
        headers?.forEach { commonHeaders[$0] = $1 }
        parameters?.forEach { commonParameters[$0] = $1 }
    }
}
