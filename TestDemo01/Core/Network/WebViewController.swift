//
//  CustomWebViewController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/27.
//

import UIKit
import WebKit

class WebViewController: SKBaseController {
    private let webView = CustomWebView()
    private var urlString = ""
    
    init(url: String) {
        self.urlString = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        loadInitialURL()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.webView.callJavaScript("sendBasicMessage()")
        }
    }
    
    private func loadInitialURL() {
        
        let path = Bundle.main.path(forResource: "test2", ofType: "html") ?? ""
        let url = URL(fileURLWithPath: path)
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        webView.scrollView.maximumZoomScale = 1.0
        // 如果找不到本地文件，加载网络URL作为后备
        //        guard let url else {
        //            return
        //        }
        //        webView.load(URLRequest(url: url))
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(webView)
        
        webView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
    }
    
    private func setupWebView() {
        webView.didStartLoading = { [weak self] in
            self?.title = "加载中..."
        }
        
        webView.didFinishLoading = { [weak self] in
            self?.title = self?.webView.title
        }
        
        webView.didFailLoading = { [weak self] error in
            self?.showError(error)
        }
        
        webView.receivedScriptMessage = { [weak self] message in
            self?.handleScriptMessage(message)
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "加载失败", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.loadInitialURL()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func handleScriptMessage(_ message: WKScriptMessage) {
        print("收到JS消息: \(message.name) - \(message.body)")
        switch message.name {
        case "nativeHandler":
            if let dict = message.body as? [String: Any] {
                handleNativeMessage2(dict)
            }
        default:
            break
        }
    }
   
    deinit {
        print("WebViewController 已释放")
    }
}

extension WebViewController {
    
    private func handleNativeMessage1(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        switch action {
                case "showToast":
                    if let text = message["message"] as? String {
                        showToast(text)
                    }
        
                case "processData":
                    if let data = message["data"] as? [String: Any] {
                        print("收到复杂数据: \(data)")
                        sendResponseToJS(["status": "processed"])
                    }
        
                case "roundTripTest":
                    if let sentTime = message["sentTime"] as? Int {
                        let roundTripTime = Int(Date().timeIntervalSince1970 * 1000) - sentTime
                        sendResponseToJS(["roundTripTime": roundTripTime])
                    }
        
                case "customMessage":
                    if let content = message["content"] as? String {
                        showAlert(title: "自定义消息", message: content)
                    }
   
        default:
            print("未知action: \(action)")
        }
    }
    
    
    
    private func sendResponseToJS(_ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                webView.callJavaScript("window._handleNativeResponse(\(jsonString))")
            }
        } catch {
            print("JSON序列化错误: \(error)")
        }
    }
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alert.dismiss(animated: true)
        }
    }
    
}


extension WebViewController {
    
    private func handleNativeMessage2(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        switch action {
        case "logMessage":
            handleLogMessage(message)
        case "showAlert":
            handleShowAlert(message)
        case "getDeviceInfo":
            handleGetDeviceInfo(message)
        case "roundTripTest":
            handleRoundTripTest(message)
        default:
            print("未知action: \(action)")
        }
    }
    
    
    private func handleLogMessage(_ message: [String: Any]) {
        print("JS日志: \(message["content"] ?? "")")
    }
    
    private func handleShowAlert(_ message: [String: Any]) {
        let alertMessage = message["message"] as? String ?? "默认消息"
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "来自JS的Alert", message: alertMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func handleGetDeviceInfo(_ message: [String: Any]) {
        let deviceInfo = [
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "model": UIDevice.current.model,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        let script = "window.nativeCallback(\(String(describing: deviceInfo.jsonString)))"
        webView.callJavaScript(script)
    }
    
    private func handleRoundTripTest(_ message: [String: Any]) {
        guard let sentTime = message["sentTime"] as? TimeInterval else { return }
        
        let roundTripTime = Date().timeIntervalSince1970 * 1000 - sentTime
        let response = [
            "status": "success",
            "roundTripTime": roundTripTime,
            "receivedAt": Date().timeIntervalSince1970 * 1000
        ] as [String : Any]
        
        let script = "window.nativeCallback(\(String(describing: response.jsonString)))"
        webView.callJavaScript(script)
    }
}
