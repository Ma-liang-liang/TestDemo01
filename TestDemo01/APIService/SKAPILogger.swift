//
//  SKAPILogger.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit
import Moya

internal class SKAPILogger: PluginType {
    private var requestStore = [String: String]()
    private let queue = DispatchQueue(label: "com.skapi.logger")
    
    func willSend(_ request: RequestType, target: TargetType) {
        guard SKAPIConfiguration.shared.logEnabled else { return }
        
        let uuid = UUID().uuidString
        var log = ""
        
        log += "\n------- Request Start -------\n"
        log += "UUID: \(uuid)\n"
        log += "URL: \(request.request?.url?.absoluteString ?? "")\n"
        log += "Method: \(request.request?.httpMethod ?? "")\n"
        log += "Headers: \(request.request?.allHTTPHeaderFields?.jsonString ?? "{}")\n"
        if let body = request.request?.httpBody {
            log += "Body: \(String(data: body, encoding: .utf8) ?? "")\n"
        }
        log += "------- Request End -------\n"
        
        queue.sync {
            requestStore[uuid] = log
        }
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard SKAPIConfiguration.shared.logEnabled else { return }
        
        queue.sync {
            guard let uuid = requestStore.keys.first else { return }
            var log = requestStore.removeValue(forKey: uuid) ?? ""
            
            log += "\n------- Response Start -------\n"
            switch result {
            case .success(let response):
                log += "Status Code: \(response.statusCode)\n"
                log += "Response: \(response.data.prettyPrintedJSON ?? "Invalid JSON")\n"
            case .failure(let error):
                log += "Error: \(error.localizedDescription)\n"
            }
            log += "------- Response End -------\n"
            
            print(log)
        }
    }
}

// JSON格式化扩展
private extension Data {
    var prettyPrintedJSON: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

private extension Dictionary {
    var jsonString: String {
        guard let data = try? JSONSerialization.data(withJSONObject: self),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
