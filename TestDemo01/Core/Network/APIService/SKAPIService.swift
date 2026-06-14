////
////  SKAPIService.swift
////  TestDemo
////
////  Created by 马亮亮 on 2025/2/18.
////
//
//import Moya
//import Alamofire
//import SmartCodable
//
//
//public final class SKAPIService {
//    public static let shared = SKAPIService()
//    
//    private let provider: MoyaProvider<MultiTarget>
//    private let configuration = SKAPIConfiguration.shared
//    
//    public init() {
//        let session = Session(
//            configuration: .default,
//            startRequestsImmediately: false
//        )
//        
//        self.provider = MoyaProvider<MultiTarget>(
//            session: session,
//            plugins: [SKAPILogger()]
//        )
//    }
//    
//    // MARK: - 基础请求
//    public func requestJSONAPI<T: SKAPITarget>(
//        _ target: T,
//        completion: @escaping (Result<String, SKAPIError>) -> Void
//    ) {
//        let endpoint = createEndpoint(for: target)
//        
//        provider.request(endpoint) { [weak self] result in
//            self?.handleResult(result, completion: completion)
//        }
//    }
//    
//    // MARK: - 模型请求
//    public func requestModelAPI<T: SKAPITarget, U: SmartCodable>(
//        _ target: T,
//        modelType: U.Type,
//        completion: @escaping (Result<U, SKAPIError>) -> Void
//    ) {
//        requestJSONAPI(target) { result in
//            switch result {
//            case .success(let jsonString):
//                do {
//                    guard let data = jsonString.data(using: .utf8) else {
//                        throw SKAPIError(code: -1001, message: "数据转换失败")
//                    }
//                    let model = try U.deserialize(from: data) ?? U()
//                    completion(.success(model))
//                } catch {
//                    let skError = error as? SKAPIError ?? SKAPIError(code: -1002, message: "模型解析失败")
//                    completion(.failure(skError))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//}
//
//private extension SKAPIService {
//    // 创建请求端点
//    func createEndpoint<T: SKAPITarget>(for target: T) -> MultiTarget {
//        let mergedHeaders = configuration.commonHeaders.merging(target.customHeaders ?? [:]) { $1 }
//        let mergedParameters = configuration.commonParameters.merging(target.customParameters ?? [:]) { $1 }
//        
//        let task: Task
//        if let files = target.uploadFiles, !files.isEmpty {
//            task = .uploadMultipart(createFormData(files: files, parameters: mergedParameters))
//        } else {
//            task = .requestParameters(parameters: mergedParameters, encoding: JSONEncoding.default)
//        }
//        
//        let endpoint = Endpoint(
//            url: targetURL(target),
//            sampleResponseClosure: { .networkResponse(200, Data()) },
//            method: target.method.alamofireMethod,
//            task: task,
//            httpHeaderFields: mergedHeaders
//        )
//        
//        return MultiTarget(endpoint as! TargetType)
//    }
//
//    // 构建目标URL
//    func targetURL<T: SKAPITarget>(_ target: T) -> String {
//        let baseURL = configuration.baseURL ?? URL(string: "about:blank")!
//        return baseURL.appendingPathComponent(target.path).absoluteString
//    }
//
//    // 创建表单数据
//    func createFormData(files: [SKUploadFile], parameters: [String: Any]) -> [MultipartFormData] {
//        var formData = parameters.map { key, value in
//            MultipartFormData(
//                provider: .data("\(value)".data(using: .utf8)!),
//                name: key
//            )
//        }
//        
//        files.forEach { file in
//            switch file.data {
//            case .data(let data):
//                formData.append(MultipartFormData(
//                    provider: .data(data),
//                    name: file.name,
//                    fileName: file.fileName,
//                    mimeType: file.mimeType
//                ))
//            case .file(let url):
//                formData.append(MultipartFormData(
//                    provider: .file(url),
//                    name: file.name,
//                    fileName: file.fileName,
//                    mimeType: file.mimeType
//                ))
//            }
//        }
//        
//        return formData
//    }
//    
//    // 处理响应结果
//    func handleResult(_ result: Result<Response, MoyaError>,
//                      completion: @escaping (Result<String, SKAPIError>) -> Void) {
//        switch result {
//        case .success(let response):
//            do {
//                // 转换为JSON字符串
//                let jsonString = try response.mapString()
//                
//                // 业务码拦截检查
//                if let json = try? response.mapJSON() as? [String: Any],
//                   let code = json["code"] as? Int,
//                   configuration.interceptCodes.contains(code) {
//                    
//                    let message = json["message"] as? String ?? ""
//                    let handled = configuration.interceptor?(code, message, json) ?? false
//                    if handled { return }
//                }
//                
//                completion(.success(jsonString))
//            } catch {
//                completion(.failure(SKAPIError(code: -1003, message: "JSON解析失败")))
//            }
//            
//        case .failure(let error):
//            let skError = SKAPIError(
//                code: error.errorCode,
//                message: error.localizedDescription
//            )
//            completion(.failure(skError))
//        }
//    }
//}
