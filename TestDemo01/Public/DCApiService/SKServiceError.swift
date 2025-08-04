//
//  DCError.swift
//  DicosApp
//
//  Created by edy on 2021/7/31.
//

import UIKit

///整个项目使用一个error类型，不同的error用不同的错误码
class SKServiceError: LocalizedError, CustomStringConvertible {

    var code = ""
    
    var reason = ""
    
    var api: String?
    
    init(code: String, reason: String, api: String? = nil) {
        self.code = code
        self.reason = reason
        self.api = api
    }
    
    var description: String {
        var desc: String!
        if let api = api {
            desc = "api = \(api)\n errorCode = \(code)\n errorReason = \(reason)"
        } else {
            desc = "errorCode = \(code)\n errorReason = \(reason)"
        }
        return desc
    }
    
    var errorDescription: String? {
        return reason
    }
}

struct DCHttpCode {
    
    static let successCode = 200
    
    static let noNetWork = ""
 
    static let dataDeserializeFailure = 0
    
    static let failedToken = 0
    
    static let registerFengKong = 0
    
    static let loginFengKong = 0
   
    static let signFengKong = 0
  
    static let faieldAlert = 0
    
    static let noneToken = 0
    
}


