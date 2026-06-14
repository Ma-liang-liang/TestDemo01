//
//  SKAPITarget.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit

public protocol SKAPITarget {
    var baseUrl: String { get }
    var path: String { get }
    var method: SKHTTPMethod { get }
    var customHeaders: [String: String]? { get }
    var customParameters: [String: Any]? { get }
    var uploadFiles: [SKUploadFile]? { get }
}

public extension SKAPITarget {
    var baseUrl: String { "" }
    var path: String { "" }
    var method: SKHTTPMethod { .post }
    var customHeaders: [String: String]? { nil }
    var customParameters: [String: Any]? { nil }
    var uploadFiles: [SKUploadFile]? { nil }
}
