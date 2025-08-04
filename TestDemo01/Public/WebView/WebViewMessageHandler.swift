//
//  WebViewMessageHandler.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/27.
//

import UIKit
import WebKit

class WebViewMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WebViewMessageHandlerDelegate?
    
    init(delegate: WebViewMessageHandlerDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.didReceiveScriptMessage(message)
    }
    
    deinit {
        print("WebViewMessageHandler deinit")
    }
}

protocol WebViewMessageHandlerDelegate: AnyObject {
    func didReceiveScriptMessage(_ message: WKScriptMessage)
}
