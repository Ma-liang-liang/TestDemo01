//
//  MockApi.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/19.
//

enum MockApi {
    
    case getPosts
    
    case getUsers
    
    case postPosts
}

extension MockApi: SKApiProtocol {
    
    var path: String {
        switch self {
        case .getPosts:
            return "/posts/1"
        case .getUsers:
            return "/users"
        case .postPosts:
            return "/posts"

        }
    }
    
    var methodType: SKMethodType {
        switch self {
        case .getPosts, .getUsers:
            return .get
        default:
            return .post
        }
    }
    
    var baseUrlString: String {
        "https://jsonplaceholder.typicode.com"
    }
}

extension SKAPIConfiguration {
    
    static func addConfig() {
        
        SKApiConfig.needDebugInfo = true
    }
}

