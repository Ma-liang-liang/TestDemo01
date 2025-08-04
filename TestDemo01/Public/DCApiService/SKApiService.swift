//
//  DCNet.swift
//  DicosApp
//
//  Created by edy on 2021/7/31.
//

import UIKit
import SmartCodable
import Moya
import SwifterSwift

class SKApiService: NSObject {
    
    typealias SuccessCallBack = ((String) -> Void)
    typealias FailureCallBack = ((NSError) -> Void)
    
    
    static func sendObjectRequest<T: SmartCodable>(apiProtocol: SKApiProtocol, modelType: T.Type ,desinatedPath: String? = "data", successCallBack: @escaping ((T?) -> ()), failureCallBack: @escaping FailureCallBack) {
        
        sendRequest(apiProtocol: apiProtocol, successCallBack: { json in
            let model = T.deserialize(from: json,designatedPath: desinatedPath)
            successCallBack(model)
        }, failureCallBack: failureCallBack)
    }
    
    static func sendArrayRequest<T: SmartCodable>(apiProtocol: SKApiProtocol, modelType: T.Type, desinatedPath: String? = "data", successCallBack: @escaping (([T]) -> ()), failureCallBack: @escaping FailureCallBack) {
        
        sendRequest(apiProtocol: apiProtocol, successCallBack: { json in
            let models = [T].deserialize(from: json, designatedPath: desinatedPath)?.compactMap({ $0 }) ?? []
            successCallBack(models)
        }, failureCallBack: failureCallBack)
    }
    
    static func sendRequest(apiProtocol: SKApiProtocol, successCallBack: @escaping SuccessCallBack, failureCallBack: @escaping FailureCallBack) {
        
        let params = SKApiConfig.commonParams + apiProtocol.parameters
        let headers = SKApiConfig.commonHeaders + apiProtocol.headers
        
        let target = SKApiProtcolTarget(baseUrl: apiProtocol.baseUrlString,
                                        path: apiProtocol.path,
                                        method: apiProtocol.methodType,
                                        requestType: apiProtocol.requestType,
                                        headers: headers,
                                        parameters: params,
                                        contentType: apiProtocol.contentType,
                                        multipartDatas: apiProtocol.multipartDatas,
                                        downloadDestination: apiProtocol.downloadDestination)
        
        let provider = SKApiService.getProviderByTarget(target: target)
        let m_target = MultiTarget(target)
        ///获取调试信息
        var logInfo = "\n apiPath = \n"  + apiProtocol.baseUrlString + apiProtocol.path + "\n headers = \n \(headers)" + "\n params = \n \(params)"
        provider.request(m_target, callbackQueue: apiProtocol.callBackQueue) { result in
            switch result {
            case .success(let response):
                
                let jsonStr = response.data.string(encoding: .utf8) ?? ""
                
                logInfo += "\n responseString = \(jsonStr)"
                
                if response.statusCode != DCHttpCode.successCode {
                    let error = NSError(domain: "\(target.path)\n\(jsonStr)", code: response.statusCode)
                    failureCallBack(error)
                    return
                }
//                let dict = JSONSerialization.getDictionaryFromJSONData(jsonData: response.data) ?? [:]
//                guard let code = dict["code"] as? String else {
//                    print("code解析失败")
//                    return
//                }
//                let intCode = Int(code) ?? 0
//                if SKApiConfig.listenerCodes.contains(intCode) {
//                    SKApiConfig.listenerCallBack?(intCode)
//                    return
//                }
                
                if response.statusCode == (DCHttpCode.successCode) {
                    successCallBack(jsonStr)
                } else {
//                    let message = (dict["message"] as? String) ?? ""
//                    let service_error = NSError(domain: "\(target.path)\n\(message)", code: response.statusCode)
//                    failureCallBack(service_error)
                }
            case .failure(let error):
                
                logInfo += "\n error = \(error)"
                
                if SKApiConfig.listenerCodes.contains(error.errorCode) {
                    SKApiConfig.listenerCallBack?(error.errorCode)
                    return
                }
                let service_error = NSError(domain: "\(target.path)\n\(String(describing: error.errorDescription))", code: error.errorCode)
                failureCallBack(service_error)
            }
            ///判断是否需要log信息
            if SKApiConfig.needDebugInfo {
                ///打印接口调试信息
                print(logInfo)
            }
        }
    }
    
    private static func getProviderByTarget(target: TargetType) -> MoyaProvider<MultiTarget> {
        let provider = MoyaProvider<MultiTarget>(endpointClosure: { (target: MultiTarget) -> Endpoint in     // 设置header
            let url = target.baseURL.appendingPathComponent(target.path).absoluteString
            let headers:[String: String] = target.headers ?? [:]
            let endpoint = Endpoint(url: url, sampleResponseClosure: { () -> EndpointSampleResponse in
                    .networkResponse(200, target.sampleData)
            }, method: target.method, task: target.task, httpHeaderFields: headers)
            return endpoint
        }, requestClosure: { (point: Endpoint, closure: MoyaProvider<MultiTarget>.RequestResultClosure) in
            do {
                var request = try point.urlRequest()
                request.timeoutInterval = 30
                closure(.success(request))
            } catch {
                closure(.failure(MoyaError.requestMapping(point.url)))
            }
        }, stubClosure: { (target: MultiTarget) -> StubBehavior in
            return .never
        }, callbackQueue: DispatchQueue.main, plugins: [NetworkActivityPlugin { (type, target) in
            switch type {
            case .began:
                break
            case .ended:
                break
            }
        }])
        return provider
    }
    
}

extension SKApiService {
    
    static func sendObjectRequest<T: SmartCodable>(apiProtocol: SKApiProtocol, modelType: T.Type ,desinatedPath: String? = "data") async throws -> T? {
        
        try await withCheckedThrowingContinuation { continuation in
            sendObjectRequest(apiProtocol: apiProtocol, modelType: modelType) { model in
                continuation.resume(returning: model)
            } failureCallBack: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func sendArrayRequest<T: SmartCodable>(apiProtocol: SKApiProtocol, modelType: T.Type, desinatedPath: String? = "data") async throws -> [T] {
        
        try await withCheckedThrowingContinuation { continuation in
            sendArrayRequest(apiProtocol: apiProtocol, modelType: modelType) { models in
                continuation.resume(returning: models)
            } failureCallBack: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func sendRequest(apiProtocol: SKApiProtocol) async throws -> String {
        
        try await withCheckedThrowingContinuation { continuation in
            sendRequest(apiProtocol: apiProtocol) { json in
                continuation.resume(returning: json)
            } failureCallBack: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
}
