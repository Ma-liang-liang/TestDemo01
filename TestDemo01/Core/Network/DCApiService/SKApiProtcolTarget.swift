//
//  DCApiProtcolTarget.swift
//  DicosApp
//
//  Created by edy on 2021/9/8.
//

import UIKit
import Moya

struct SKApiProtcolTarget: TargetType {

    private let _baseUrl: String
    
    private let _path: String
    
    private let _headers: [String: String]?
    
    private let _parameters: [String: Any]

    private let _method: SKMethodType

    private let _requestType: SKRequestType
    
    private let _contentType: SKApiContentType
    
    private let _multipartDatas: [SKMultiPartFormData]?
    
    private let _downloadDestination: SKDownloadDestination?
    
    init(baseUrl: String,
         path: String,
         method: SKMethodType,
         requestType: SKRequestType,
         headers: [String: String]? = nil,
         parameters: [String: Any],
         contentType: SKApiContentType,
         multipartDatas: [SKMultiPartFormData]? = nil,
         downloadDestination: SKDownloadDestination? = nil) {
        
        _baseUrl = baseUrl
        _path = path
        _headers = headers
        _method = method
        _requestType = requestType
        _parameters = parameters
        _contentType = contentType
        _multipartDatas = multipartDatas
        _downloadDestination = downloadDestination
        
    }

    var baseURL: URL {
        return URL(string: _baseUrl) ?? URL(fileURLWithPath: "")
    }
    
    var path: String {
        return _path
    }
    
    var method: Moya.Method {
        switch _method {
        case .post:
            return .post
        case .get:
            return .get
        case .put:
            return .put
        }
    }
    
    var sampleData: Data {
        guard let data = "{}".data(using: .utf8) else {
            return Data()
        }
        return data
    }
        
    var task: Task {
        ///设置默认参数
        let params = _parameters
   
        switch _requestType {
        case .regular:
            if method == .post {
                return .requestParameters(parameters: params, encoding: URLEncoding.default)
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .upload:
            guard let multipartDatas = _multipartDatas?.map({ $0.asMoyaMultipartFormData() }) else {
                return .uploadCompositeMultipart([], urlParameters: params)
            }
            return .uploadCompositeMultipart(multipartDatas, urlParameters: params)
        case .download:
            guard let downloadDestination = _downloadDestination else {
                return .downloadDestination(SKDownloadDestination.defaultDestination)
            }
            return .downloadDestination(downloadDestination.asMoyaDownloadDestination())
        }
    }
    
    var headers: [String: String]? {
        var headers: [String: String] = [:]
        if let _headers = _headers {
            headers = _headers
        }
        headers["Content-Type"] = _contentType.rawValue
        return headers
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
    
}
