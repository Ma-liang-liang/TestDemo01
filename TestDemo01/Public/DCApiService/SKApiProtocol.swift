//
//  DCTargetType.swift
//  DicosApp
//
//  Created by edy on 2021/7/31.
//

import UIKit
import Moya

enum SKApiContentType: String {
    case json = "application/json;charset=utf-8"
    case urlEncoding = "application/x-www-form-urlencoded"
    case multipart = "multipart/form-data"
}

enum SKMethodType: String {
    case get = "get"
    case post = "post"
    case put = "put"
}

enum SKRequestType: CaseIterable {

    case regular
    
    case upload
    
    case download
}


protocol SKApiProtocol {

    var baseUrlString: String { get }
    
    var path: String { get }

    /// 修改请求方式，不直接使用Moya的
    var methodType: SKMethodType { get }
    
    var headers: [String: String] { get }
    
    var parameters: [String: Any] { get }
    
    var requestType: SKRequestType { get }
    
    var contentType: SKApiContentType { get }
    
    var multipartDatas: [SKMultiPartFormData] { get }
    
    var downloadDestination: SKDownloadDestination? { get }
      
    var callBackQueue: DispatchQueue { get }
        
}
 
extension SKApiProtocol {
     
    var baseUrlString: String { SKApiConfig.serviceBaseURL }

    var path: String { "" }
            
    var headers: [String: String] { [:] }
                
    var methodType: SKMethodType { .post }
    
    var requestType: SKRequestType { .regular }

    var contentType: SKApiContentType { .json }
    
    var parameters: [String: Any] { [:] }
    
    var multipartDatas: [SKMultiPartFormData] { [] }
    
    var downloadDestination: SKDownloadDestination? { nil }
    
    var callBackQueue: DispatchQueue { .main }
        
}

