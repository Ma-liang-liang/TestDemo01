//
//  ReqResApi.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/19.
//

///base
enum ReqResApi {
    
    case getUsers(page: Int)
    
    case getSingleUser(id: Int)
    
    case createUser(name: String, job: String)
}

extension ReqResApi: SKApiProtocol {
    
    var path: String {
        switch self {
        case let .getUsers(page):
            return "/api/users?page=\(page)"
        case let .getSingleUser(id):
            return "/api/users/\(id)"
        case .createUser:
            return "/api/users"
        }
    }
    
    var parameters: [String : Any] {
        var params: [String: Any] = [:]
        switch self {
        case let .createUser(name, job):
            params["name"] = name
            params["job"] = job
            return params
        default:
            return params
        }
    }
    
    var methodType: SKMethodType {
        switch self {
        case .getUsers, .getSingleUser:
            return .get
        default:
            return .post
        }
    }
    
    var baseUrlString: String {
        "https://reqres.in"
    }
    
}
