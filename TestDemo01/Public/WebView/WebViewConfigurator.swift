//
//  WebViewConfigurator.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/27.
//

import UIKit
import WebKit

class WebViewConfigurator {
    private var messageHandlers = [String: WebViewMessageHandler]()
    
    func createConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        configuration.allowsInlineMediaPlayback = true
        
        // 可在此注入初始 JavaScript
        let userContentController = WKUserContentController()
        let script = WKUserScript(source: "console.log('WebView初始化完成')",
                                injectionTime: .atDocumentStart,
                                forMainFrameOnly: false)
        userContentController.addUserScript(script)
        
        configuration.userContentController = userContentController
        return configuration
    }
    
    func addMessageHandler(name: String, delegate: WebViewMessageHandlerDelegate) {
        let handler = WebViewMessageHandler(delegate: delegate)
        messageHandlers[name] = handler
    }
    
    func applyHandlers(to configuration: WKWebViewConfiguration) {
        messageHandlers.forEach { name, handler in
            configuration.userContentController.add(handler, name: name)
        }
    }
    
    func cleanUp(configuration: WKWebViewConfiguration) {
        messageHandlers.keys.forEach { name in
            configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
        messageHandlers.removeAll()
    }
    
    deinit {
        print("Configurator 已释放")
    }
}
