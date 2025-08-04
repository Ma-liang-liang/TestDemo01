//
//  CustomWebView.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/27.
//

import UIKit
@preconcurrency import WebKit

class CustomWebView: WKWebView {
    // 进度条
    private var progressView: UIProgressView!
    private var configurator = WebViewConfigurator()
    
    // 回调闭包
    var didStartLoading: (() -> Void)?
    var didFinishLoading: (() -> Void)?
    var didFailLoading: ((Error) -> Void)?
    var progressChanged: ((Float) -> Void)?
    var receivedScriptMessage: ((WKScriptMessage) -> Void)?
    
    // 初始化
    init() {
        let configuration = configurator.createConfiguration()
        
        super.init(frame: .zero, configuration: configuration)
        
        // 添加消息处理器（此时self已初始化完成）
        configurator.addMessageHandler(name: "nativeHandler", delegate: self)
        configurator.applyHandlers(to: configuration)
        
        setupWebView()
        setupProgressView()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        removeObservers()
        configurator.cleanUp(configuration: configuration)
        print("WebView 已释放")
    }
    
    // MARK: - 设置方法
    private func setupWebView() {
        navigationDelegate = self
        uiDelegate = self
        allowsBackForwardNavigationGestures = true
        scrollView.showsVerticalScrollIndicator = false
    }
    
    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = .systemPink
        progressView.trackTintColor = .clear
        progressView.isHidden = true
        addSubview(progressView)
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
    }
    
    private func setupObservers() {
        addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }
    
    private func removeObservers() {
        removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
    }
    
    // MARK: - 公开方法
    func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        load(URLRequest(url: url))
    }
    
    func callJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        evaluateJavaScript(script, completionHandler: completion)
    }
    
    // MARK: - KVO 观察
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case #keyPath(WKWebView.estimatedProgress):
            let progress = Float(estimatedProgress)
            progressView.progress = progress
            progressView.isHidden = progress == 1
            progressChanged?(progress)
            
        case #keyPath(WKWebView.title):
            break // 可通过回调处理
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - WKNavigationDelegate
extension CustomWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        didStartLoading?()
        progressView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishLoading?()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFailLoading?(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        didFailLoading?(error)
    }
}

// MARK: - WKUIDelegate
extension CustomWebView: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // 实现 JavaScript alert 处理
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler()
        })
        
        if let rootVC = UIScreen.getKeyWindow()?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// MARK: - WebViewMessageHandlerDelegate
extension CustomWebView: WebViewMessageHandlerDelegate {
    func didReceiveScriptMessage(_ message: WKScriptMessage) {
        receivedScriptMessage?(message)
    }
}
