//
//  NetworkManager.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/16.
//

import Foundation
import Alamofire
import Network
import Security
import SmartCodable // 导入 SmartCodable

// MARK: - 网络错误
public struct SNNetworkError: Error {
    public let code: Int
    public let message: String
    public let underlyingError: Error?
    
    public var description: String {
        return "错误[\(code)]: \(message)"
    }
    
    public init(code: Int, message: String, underlyingError: Error? = nil) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
    }
    
    // 预定义错误
    public static let invalidURL = SNNetworkError(code: -1001, message: "无效的URL")
    public static let noNetwork = SNNetworkError(code: -1002, message: "网络不可用")
    public static let timeout = SNNetworkError(code: -1003, message: "请求超时")
    public static let cancelled = SNNetworkError(code: -1004, message: "请求已取消")
    public static let parseError = SNNetworkError(code: -1005, message: "数据解析错误")
    public static let noData = SNNetworkError(code: -1006, message: "响应数据为空")
    public static let sslError = SNNetworkError(code: -1009, message: "SSL证书配置错误")
    
    public static func httpError(_ code: Int, _ message: String) -> SNNetworkError {
        return SNNetworkError(code: code, message: message)
    }
    
    public static func parseError(_ description: String) -> SNNetworkError {
        return SNNetworkError(code: -1005, message: "数据解析错误: \(description)")
    }
    
    public static func sslError(_ description: String) -> SNNetworkError {
        return SNNetworkError(code: -1009, message: "SSL证书配置错误: \(description)")
    }
}

// MARK: - HTTP方法
public enum SNHTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - 证书配置类型
public enum SNSSLConfigType {
    case none
    case oneWay(certificateData: Data)
    case twoWay(serverCertData: Data, clientP12Data: Data, p12Password: String)
}

// MARK: - 请求任务
public class SNRequestTask {
    private let dataRequest: DataRequest?
    private let uploadRequest: UploadRequest?
    private let downloadRequest: DownloadRequest?
    
    init(dataRequest: DataRequest) {
        self.dataRequest = dataRequest
        self.uploadRequest = nil
        self.downloadRequest = nil
    }
    
    init(uploadRequest: UploadRequest) {
        self.dataRequest = nil
        self.uploadRequest = uploadRequest
        self.downloadRequest = nil
    }
    
    init(downloadRequest: DownloadRequest) {
        self.dataRequest = nil
        self.uploadRequest = nil
        self.downloadRequest = downloadRequest
    }
    
    public func cancel() {
        dataRequest?.cancel()
        uploadRequest?.cancel()
        downloadRequest?.cancel()
    }
}

// MARK: - 拦截器配置
public typealias SNInterceptorHandler = (Int, Any?) -> Bool

public struct SNInterceptorConfig {
    public let codes: [Int]
    public let handler: SNInterceptorHandler
    
    public init(codes: [Int], handler: @escaping SNInterceptorHandler) {
        self.codes = codes
        self.handler = handler
    }
}

// MARK: - 回调类型
public typealias SNProgressHandler = (Double) -> Void
public typealias SNSuccessHandler<T> = (T) -> Void
public typealias SNFailureHandler = (SNNetworkError) -> Void
public typealias SNJSONHandler = (String) -> Void

// MARK: - 网络管理器
public class SNNetworkManager {
    
    // MARK: - 单例
    public static let shared = SNNetworkManager()
    
    // MARK: - 私有属性
    private var session: Session
    private var networkMonitor: NWPathMonitor?
    private var isNetworkAvailable = true
    
    // 自定义的 SessionDelegate，用于处理双向认证
    private class SNClientCertSessionDelegate: SessionDelegate {
        private let clientIdentity: SecIdentity
        init(clientIdentity: SecIdentity) {
            self.clientIdentity = clientIdentity
            super.init()
        }
        override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
                super.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
                return
            }
            let credential = URLCredential(identity: clientIdentity, certificates: nil, persistence: .forSession)
            completionHandler(.useCredential, credential)
        }
    }
    
    // MARK: - 公共配置属性
    public var baseURL: String = ""
    public var defaultHeaders: [String: String] = [:]
    public var defaultParameters: [String: Any] = [:]
    public var timeout: TimeInterval = 30.0
    public var enableLog: Bool = true
    public var interceptors: [SNInterceptorConfig] = []
    
    public var sslConfig: SNSSLConfigType = .none {
        didSet { setupSession() }
    }
    
    // MARK: - 初始化
    public init() {
        self.session = Session(configuration: .default)
        setupNetworkMonitoring()
        setupSession()
    }
    
    // MARK: - 设置会话
    private func setupSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        
        var serverTrustManager: ServerTrustManager?
        var sessionDelegate: SessionDelegate = SessionDelegate()
        
        switch sslConfig {
        case .none:
            serverTrustManager = nil
        case .oneWay(let certificateData):
            do {
                serverTrustManager = try createOneWayEvaluators(certificateData: certificateData)
            } catch {
                log("❌ 单向认证配置失败: \(error.localizedDescription)")
            }
        case .twoWay(let serverCertData, let clientP12Data, let p12Password):
            do {
                serverTrustManager = try createOneWayEvaluators(certificateData: serverCertData)
                let identity = try createClientIdentity(p12Data: clientP12Data, password: p12Password)
                sessionDelegate = SNClientCertSessionDelegate(clientIdentity: identity)
            } catch {
                log("❌ 双向认证配置失败: \(error.localizedDescription)")
            }
        }
        
        session = Session(
            configuration: configuration,
            delegate: sessionDelegate,
            serverTrustManager: serverTrustManager
        )
    }
    
    // ... 其他基础方法 (createOneWayEvaluators, log, buildFullURL等保持不变) ...
    // MARK: - 创建单向认证评估器 (服务器证书验证)
    private func createOneWayEvaluators(certificateData: Data) throws -> ServerTrustManager {
        guard let host = URL(string: baseURL)?.host else {
            throw SNNetworkError.sslError("baseURL无效，无法提取用于SSL Pinning的主机名")
        }
        
        let certificate = SecCertificateCreateWithData(nil, certificateData as CFData)
        
        guard let cert = certificate else {
            throw SNNetworkError.sslError("无法根据提供的数据创建SecCertificate")
        }
        
        let trustEvaluator = PinnedCertificatesTrustEvaluator(certificates: [cert])
        
        log("🔒 SSL Pinning已为Host [\(host)] 配置")
        return ServerTrustManager(evaluators: [host: trustEvaluator])
    }
    
    // MARK: - 创建客户端证书身份 (用于双向认证)
    private func createClientIdentity(p12Data: Data, password: String) throws -> SecIdentity {
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: password
        ]
        
        var items: CFArray?
        // 从.p12数据中导入身份和证书
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)
        
        guard status == errSecSuccess, let unwrappedItems = items as? [[String: Any]], let firstItem = unwrappedItems.first else {
            throw SNNetworkError.sslError("无法从.p12文件导入身份，请检查密码或文件格式。状态码: \(status)")
        }
        
        // 字典中通常包含 kSecImportItemIdentity, kSecImportItemTrust, kSecImportItemCertChain
        guard let identity = firstItem[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw SNNetworkError.sslError(".p12文件中未找到客户端身份(SecIdentity)")
        }
        
        log("🔑 客户端证书身份已成功加载")
        return identity
    }
    
    // MARK: - 网络监控
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
            if self?.enableLog ?? false {
                self?.log("网络状态已更新: \(path.status == .satisfied ? "可用" : "不可用")")
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
    }
    
    // MARK: - 日志输出
    private func log(_ message: String) {
        guard enableLog else { return }
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        NSLog("[\(timestamp)] SNNetwork: \(message)")
    }
    
    // MARK: - 构建完整URL
    private func buildFullURL(_ endpoint: String, baseURL: String? = nil) -> String {
        let finalBaseURL = baseURL ?? self.baseURL
        
        if endpoint.hasPrefix("http://") || endpoint.hasPrefix("https://") {
            return endpoint
        }
        
        if finalBaseURL.isEmpty {
            return endpoint
        }
        
        let base = finalBaseURL.hasSuffix("/") ? String(finalBaseURL.dropLast()) : finalBaseURL
        let path = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        
        return base + path
    }
    
    // MARK: - 合并参数
    private func mergeParameters(_ requestParams: [String: Any]?) -> [String: Any] {
        var params = defaultParameters
        requestParams?.forEach { params[$0.key] = $0.value }
        return params
    }
    
    // MARK: - 合并Headers
    private func mergeHeaders(_ requestHeaders: [String: String]?) -> HTTPHeaders {
        var headers = defaultHeaders
        requestHeaders?.forEach { headers[$0.key] = $0.value }
        return HTTPHeaders(headers)
    }
    
    // MARK: - 转换HTTP方法
    private func convertHTTPMethod(_ method: SNHTTPMethod) -> HTTPMethod {
        return HTTPMethod(rawValue: method.rawValue)
    }
    
    // MARK: - 检查拦截器
    private func checkInterceptors(statusCode: Int, response: Any?) -> Bool {
        for interceptor in interceptors {
            if interceptor.codes.contains(statusCode) {
                return interceptor.handler(statusCode, response)
            }
        }
        return false
    }
    
    // MARK: - 转换AFError
    private func convertAFError(_ afError: AFError) -> SNNetworkError {
        switch afError {
        case .invalidURL(let url):
            return SNNetworkError(code: -1001, message: "无效的URL: \(url)")
        case .responseValidationFailed(let reason):
            if case .unacceptableStatusCode(let code) = reason {
                return SNNetworkError.httpError(code, afError.localizedDescription)
            }
            return SNNetworkError(code: -1007, message: afError.localizedDescription)
        case .responseSerializationFailed:
            return SNNetworkError.parseError(afError.localizedDescription)
        case .requestAdaptationFailed, .requestRetryFailed:
            return SNNetworkError(code: -1008, message: afError.localizedDescription)
        case .sessionTaskFailed(let error):
            let nsError = error as NSError
            if nsError.code == NSURLErrorTimedOut {
                return SNNetworkError.timeout
            }
            if nsError.code == NSURLErrorCancelled {
                return SNNetworkError.cancelled
            }
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorServerCertificateUntrusted {
                return SNNetworkError.sslError("服务器证书不受信任。请检查SSL Pinning配置。")
            }
            return SNNetworkError(code: nsError.code, message: error.localizedDescription)
        default:
            return SNNetworkError(code: -1000, message: afError.localizedDescription)
        }
    }
    
    // MARK: - 处理响应
    private func handleResponse(
        url: String,
        response: DataResponse<Data, AFError>,
        dataSuccess: ((Data) -> Void)?,
        failure: SNFailureHandler?
    ) {
        let statusCode = response.response?.statusCode ?? 0
        
        switch response.result {
        case .success(let data):
            log("✅ 请求成功 [\(statusCode)] \(url)")
            
            if checkInterceptors(statusCode: statusCode, response: String(data: data, encoding: .utf8)) {
                return
            }
            
            dataSuccess?(data)
            
        case .failure(let afError):
            let networkError = convertAFError(afError)
            log("❌ 请求失败: \(networkError.description)")
            if checkInterceptors(statusCode: statusCode, response: networkError) { return }
            failure?(networkError)
        }
    }
    
    // MARK: - 基础请求方法 (私有化)
    // 这个方法现在只负责获取原始Data，是所有Codable请求的基础
    @discardableResult
    private func requestData(
        _ endpoint: String,
        method: SNHTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        success: ((Data) -> Void)?,
        failure: SNFailureHandler? = nil
    ) -> SNRequestTask? {
        
        guard isNetworkAvailable else {
            failure?(SNNetworkError.noNetwork)
            return nil
        }
        
        let fullURL = buildFullURL(endpoint, baseURL: baseURL)
        let finalParameters = mergeParameters(parameters)
        let finalHeaders = mergeHeaders(headers)
        
        guard let url = URL(string: fullURL) else {
            failure?(SNNetworkError.invalidURL)
            return nil
        }
        
        log("🚀 开始请求: \(method.rawValue) \(fullURL)")
        if !finalHeaders.isEmpty {
            log("   请求头: \(finalHeaders)")
        }
        if !finalParameters.isEmpty {
            log("   参数: \(finalParameters)")
        }
        
        let encoding: ParameterEncoding = (method == .GET) ? URLEncoding.default : JSONEncoding.default
        
        let request = session.request(url, method: convertHTTPMethod(method), parameters: finalParameters, encoding: encoding, headers: finalHeaders)
        
        request.responseData { [weak self] response in
            self?.handleResponse(url: fullURL, response: response, dataSuccess: success, failure: failure)
        }
        
        return SNRequestTask(dataRequest: request)
    }
    
    // MARK: - SmartCodable Support
    
    /// 发送请求并自动将JSON响应解码为单个SmartCodable模型
    /// - Parameter T: 期望的模型类型，必须遵循SmartCodable协议
    /// - Parameter keyPath: 从JSON响应的哪个字段开始解析，支持点语法，如"data.user"
    /// - Returns: SNRequestTask?
    @discardableResult
    public func requestModel<T: SmartCodable>(
        _ endpoint: String,
        method: SNHTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        keyPath: String? = nil,
        success: SNSuccessHandler<T>? = nil,
        failure: SNFailureHandler? = nil
    ) -> SNRequestTask? {
        
        return requestData(
            endpoint,
            method: method,
            parameters: parameters,
            headers: headers,
            baseURL: baseURL,
            success: { data in
                // 使用 SmartCodable 的 deserialize 方法进行解码
                if let model = T.deserialize(from: data, designatedPath: keyPath) {
                    success?(model)
                } else {
                    let errorDesc = "无法将数据解码为 '\(T.self)' 类型。检查模型定义、JSON结构或指定的keyPath ('\(keyPath ?? "nil")')。"
                    self.log("❌ 解码失败: \(errorDesc)")
                    failure?(SNNetworkError.parseError(errorDesc))
                }
            },
            failure: failure
        )
    }
    
    /// 发送请求并自动将JSON响应解码为SmartCodable模型的数组
    /// - Parameter T: 期望的模型类型，必须遵循SmartCodable协议
    /// - Parameter keyPath: 从JSON响应的哪个字段开始解析，支持点语法，如"data.list"
    /// - Returns: SNRequestTask?
    @discardableResult
    public func requestModelArray<T: SmartCodable>(
        _ endpoint: String,
        method: SNHTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        keyPath: String? = nil,
        success: SNSuccessHandler<[T]>? = nil,
        failure: SNFailureHandler? = nil
    ) -> SNRequestTask? {
        
        return requestData(
            endpoint,
            method: method,
            parameters: parameters,
            headers: headers,
            baseURL: baseURL,
            success: { data in
                // 解码为模型数组 [T]
                if let modelArray = [T].deserialize(from: data, designatedPath: keyPath) {
                    success?(modelArray)
                } else {
                    let errorDesc = "无法将数据解码为 '[\(T.self)]' 数组类型。检查模型定义、JSON结构或指定的keyPath ('\(keyPath ?? "nil")')。"
                    self.log("❌ 解码失败: \(errorDesc)")
                    failure?(SNNetworkError.parseError(errorDesc))
                }
            },
            failure: failure
        )
    }
    
    // ... 其他方法 (upload, download, cancelAllRequests等保持不变) ...
    // MARK: - JSON字符串响应
    @discardableResult
    public func requestJSON(
        _ endpoint: String,
        method: SNHTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        success: SNJSONHandler? = nil,
        failure: SNFailureHandler? = nil
    ) -> SNRequestTask? {
        
        return requestData(
            endpoint,
            method: method,
            parameters: parameters,
            headers: headers,
            baseURL: baseURL,
            success: { data in
                let jsonString = String(data: data, encoding: .utf8) ?? ""
                success?(jsonString)
            },
            failure: failure
        )
    }
    
    // MARK: - 上传文件
    @discardableResult
    public func upload<T: SmartCodable>(
        _ endpoint: String,
        data: Data,
        name: String = "file",
        fileName: String,
        mimeType: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        keyPath: String? = nil, // 上传后也可能需要解析模型
        progress: SNProgressHandler? = nil,
        success: SNSuccessHandler<T>? = nil,
        failure: SNFailureHandler? = nil
    ) -> SNRequestTask? {
        
        guard isNetworkAvailable else {
            failure?(SNNetworkError.noNetwork)
            return nil
        }
        
        let fullURL = buildFullURL(endpoint, baseURL: baseURL)
        let finalParameters = mergeParameters(parameters)
        let finalHeaders = mergeHeaders(headers)
        
        guard let url = URL(string: fullURL) else {
            failure?(SNNetworkError.invalidURL)
            return nil
        }
        
        log("📤 开始上传: \(fileName) -> \(fullURL)")
        
        let request = session.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(data, withName: name, fileName: fileName, mimeType: mimeType)
                
                for (key, value) in finalParameters {
                    if let stringValue = "\(value)".data(using: .utf8) {
                        multipartFormData.append(stringValue, withName: key)
                    }
                }
            },
            to: url,
            method: .post,
            headers: finalHeaders
        )
        
        request.uploadProgress { progressData in
            progress?(progressData.fractionCompleted)
        }
        
        request.responseData { [weak self] response in
            self?.handleResponse(
                url: fullURL,
                response: response,
                dataSuccess: { responseData in
                    if let model = T.deserialize(from: responseData, designatedPath: keyPath) {
                        success?(model)
                    } else {
                        let errorDesc = "上传成功，但无法将响应解码为 '\(T.self)' 类型。检查模型或keyPath。"
                        self?.log("❌ 解码失败: \(errorDesc)")
                        failure?(SNNetworkError.parseError(errorDesc))
                    }
                },
                failure: failure
            )
        }
        
        return SNRequestTask(uploadRequest: request)
    }
    
    // MARK: - 下载文件
    @discardableResult
    public func download(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        baseURL: String? = nil,
        destinationURL: URL,
        progress: SNProgressHandler? = nil,
        success: SNSuccessHandler<URL>? = nil,
        failure: SNFailureHandler? = nil
    ) -> SNRequestTask? {
        
        guard isNetworkAvailable else {
            failure?(SNNetworkError.noNetwork)
            return nil
        }
        
        let fullURL = buildFullURL(endpoint, baseURL: baseURL)
        let finalParameters = mergeParameters(parameters)
        let finalHeaders = mergeHeaders(headers)
        
        guard let url = URL(string: fullURL) else {
            failure?(SNNetworkError.invalidURL)
            return nil
        }
        
        log("📥 开始下载: \(fullURL) -> \(destinationURL.path)")
        
        let destination: DownloadRequest.Destination = { _, _ in
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let request = session.download(
            url,
            method: .get,
            parameters: finalParameters,
            headers: finalHeaders,
            to: destination
        )
        
        request.downloadProgress { progressData in
            progress?(progressData.fractionCompleted)
        }
        
        request.response { [weak self] response in
            switch response.result {
            case .success:
                if let finalURL = response.fileURL {
                    self?.log("✅ 下载成功: \(finalURL.path)")
                    success?(finalURL)
                } else {
                    let error = SNNetworkError.noData
                    self?.log("❌ 下载失败: \(error.description)")
                    failure?(error)
                }
            case .failure(let error):
                let networkError = self?.convertAFError(error) ?? SNNetworkError(code: -1000, message: error.localizedDescription)
                self?.log("❌ 下载失败: \(networkError.description)")
                failure?(networkError)
            }
        }
        
        return SNRequestTask(downloadRequest: request)
    }
    
    // MARK: - 取消所有请求
    public func cancelAllRequests() {
        session.cancelAllRequests()
        log("📛 已取消所有请求")
    }
    
    // MARK: - 获取网络状态
    public var isNetworkReachable: Bool {
        return isNetworkAvailable
    }
    
    // MARK: - 清理资源
    deinit {
        networkMonitor?.cancel()
        cancelAllRequests()
    }
}

// MARK: - DateFormatter扩展
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
