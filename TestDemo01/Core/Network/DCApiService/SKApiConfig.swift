//
//  DCNetConfig.swift
//  DicosApp
//
//  Created by edy on 2021/8/3.
//

import UIKit


enum ServiceBaseURL : String {
    case development = "http://dicos-dev.dicos.com.cn"
    case production = "http://brapp.belray-coffee.com"
    case UAT = "http://brapp-uat.belray-coffee.com"
    case stage = "http://brapp-stage.belray-coffee.com"
}

enum DCEnvironment : String {
    case development = "development"
    case production = "production"
    case UAT = "UAT"
    case stage = "stage"
}

class SKApiConfig: NSObject {
    
    static var appEnvironment: DCEnvironment = .production
    
    static var serviceBaseURL = ""
    ///是否需要api调试信息
    static var needDebugInfo = false
    
    static func configEnviroment(environment: DCEnvironment) {
        switch environment {
        case .development:
            //
            serviceBaseURL = ServiceBaseURL.development.rawValue
            
        case .UAT:
            serviceBaseURL = ServiceBaseURL.UAT.rawValue
            
        case .stage:
            serviceBaseURL = ServiceBaseURL.stage.rawValue
            
        case .production:
            serviceBaseURL = ServiceBaseURL.production.rawValue
            
        }
        appEnvironment = environment
    }
    
    static var commonHeaders: [String: String] = [:]
    
    static var commonParams: [String: Any] = [:]
    
    //监听指定code码回调
    static func addListenerByBusinessCodes(codes: [Int], callBack:((Int) -> Void)?) {
        listenerCodes = codes
        listenerCallBack = callBack
    }
    
    static var listenerCodes: [Int] = []
    
    static var listenerCallBack: ((Int) -> Void)?
    
}
