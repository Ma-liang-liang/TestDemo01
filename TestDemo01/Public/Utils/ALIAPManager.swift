//
//  ALIAPManager.swift
//  TestDemo
//
//  Created by as on 2025/6/14.
//

import StoreKit

/// 内购管理类 - 单例模式
final class IAPManager: NSObject {
    // MARK: - 单例实例
    static let shared = IAPManager()
    private override init() {} // 防止外部初始化
    
    // MARK: - 类型别名
    typealias ProductsRequestCompletion = (Result<[SKProduct], IAPError>) -> Void
    typealias PurchaseCompletion = (Result<String, IAPError>) -> Void
    
    // MARK: - 存储属性
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletion: ProductsRequestCompletion?
    private var purchaseCompletion: PurchaseCompletion?
    
    /// 缓存获取到的商品
    private(set) var products: [SKProduct] = []
    
    // MARK: - 初始化配置
    /// 配置内购服务（在App启动时调用）
    func configure() {
        SKPaymentQueue.default().add(self)
    }
    
    // MARK: - 产品请求
    /// 请求商品信息
    func fetchProducts(productIdentifiers: Set<String>,
                      completion: @escaping ProductsRequestCompletion) {
        // 取消已有请求
        productsRequest?.cancel()
        productsRequestCompletion = completion
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    // MARK: - 购买操作
    /// 购买商品
    func purchase(product: SKProduct, completion: @escaping PurchaseCompletion) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(.failure(.paymentNotAllowed))
            return
        }
        
        purchaseCompletion = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// 恢复购买
    func restorePurchases(completion: @escaping PurchaseCompletion) {
        purchaseCompletion = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - 工具方法
    /// 获取本地价格字符串
    func localizedPrice(for product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
    
    // MARK: - 清理方法
    deinit {
        SKPaymentQueue.default().remove(self)
    }
}

// MARK: - 错误定义
extension IAPManager {
    enum IAPError: Error, LocalizedError {
        case productRequestFailed
        case paymentNotAllowed
        case paymentCanceled
        case receiptValidationFailed
        case productNotFound
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .productRequestFailed:
                return "商品请求失败"
            case .paymentNotAllowed:
                return "设备禁止购买"
            case .paymentCanceled:
                return "用户取消购买"
            case .receiptValidationFailed:
                return "购买凭证验证失败"
            case .productNotFound:
                return "未找到对应商品"
            case .unknown(let reason):
                return reason
            }
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
    /// 收到商品响应
    func productsRequest(_ request: SKProductsRequest,
                         didReceive response: SKProductsResponse) {
        self.products = response.products
        
        if response.products.isEmpty && !response.invalidProductIdentifiers.isEmpty {
            productsRequestCompletion?(.failure(.productNotFound))
            return
        }
        
        productsRequestCompletion?(.success(response.products))
        clearRequestAndHandler()
    }
    
    /// 请求失败处理
    func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequestCompletion?(.failure(.unknown(error.localizedDescription)))
        clearRequestAndHandler()
    }
    
    /// 清理请求
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletion = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
    /// 监听交易状态变化
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            switch transaction.transactionState {
            case .purchasing:
                break // 正在支付中，无需处理
                
            case .purchased, .restored:
                // 验证购买凭证
                verifyReceipt(for: transaction) { [weak self] success in
                    guard let self else { return }
                    if success {
                        // 发货处理（根据业务需求实现）
                        deliverProduct(for: transaction.payment.productIdentifier)
                        self.purchaseCompletion?(.success(transaction.payment.productIdentifier))
                        queue.finishTransaction(transaction)
                    } else {
                        self.purchaseCompletion?(.failure(.receiptValidationFailed))
                        queue.finishTransaction(transaction)
                    }
                }
                
            case .failed:
                let error = transaction.error as? SKError
                if error?.code == .paymentCancelled {
                    purchaseCompletion?(.failure(.paymentCanceled))
                } else {
                    let reason = error?.localizedDescription ?? "未知错误"
                    purchaseCompletion?(.failure(.unknown(reason)))
                }
                queue.finishTransaction(transaction)
                purchaseCompletion = nil
                
            case .deferred:
                purchaseCompletion?(.failure(.unknown("交易被延迟")))
                queue.finishTransaction(transaction)
                purchaseCompletion = nil
                
            @unknown default:
                purchaseCompletion?(.failure(.unknown("未知交易状态")))
                queue.finishTransaction(transaction)
                purchaseCompletion = nil
            }
        }
    }
    
    /// 恢复购买完成
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // 实际交易处理在 updatedTransactions 中
    }
    
    /// 恢复购买失败
    func paymentQueue(_ queue: SKPaymentQueue,
                      restoreCompletedTransactionsFailedWithError error: Error) {
        purchaseCompletion?(.failure(.unknown(error.localizedDescription)))
        purchaseCompletion = nil
    }
}

// MARK: - 凭证验证方法
extension IAPManager {
    /// 验证购买凭证（简化版，实际需对接服务器）
    private func verifyReceipt(for transaction: SKPaymentTransaction,
                              completion: @escaping (Bool) -> Void) {
        #if DEBUG
        let sandboxURL = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
        let productionURL = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        
        // 实际应用中应从 Bundle 获取收据数据
        // let receiptData = ...
        
        // 这里简化验证流程，实际应用需：
        // 1. 获取收据数据
        // 2. 发送到自己的服务器
        // 3. 服务器与苹果验证后返回结果
        
        // 对于演示目的直接返回成功
        completion(true)
    }
}

// MARK: - 发货逻辑
extension IAPManager {
    /// 提供购买的商品/服务（根据业务需求实现）
    private func deliverProduct(for productId: String) {
        // 实际业务中：
        // 1. 解锁功能/内容
        // 2. 增加虚拟货币
        // 3. 更新用户权限
        
        // 示例：发送购买通知
        NotificationCenter.default.post(
            name: .IAPPurchaseNotification,
            object: productId
        )
        
        // 持久化购买状态（示例）
        UserDefaults.standard.set(true, forKey: productId)
    }
}

// MARK: - 通知扩展
extension Notification.Name {
    static let IAPPurchaseNotification = Notification.Name("IAPPurchaseCompleted")
}

// MARK: - 使用示例
/*
// 1. 在App启动时配置
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    IAPManager.shared.configure()
    return true
}

// 2. 获取商品
let productIDs: Set<String> = ["com.yourapp.product1", "com.yourapp.product2"]
IAPManager.shared.fetchProducts(productIdentifiers: productIDs) { result in
    switch result {
    case .success(let products):
        products.forEach { product in
            print("商品: \(product.localizedTitle), 价格: \(IAPManager.shared.localizedPrice(for: product) ?? "")")
        }
    case .failure(let error):
        print("获取商品失败: \(error.localizedDescription)")
    }
}

// 3. 购买商品
guard let product = IAPManager.shared.products.first else { return }
IAPManager.shared.purchase(product: product) { result in
    switch result {
    case .success(let productId):
        print("购买成功: \(productId)")
    case .failure(let error):
        print("购买失败: \(error.localizedDescription)")
    }
}

// 4. 恢复购买
IAPManager.shared.restorePurchases { result in
    switch result {
    case .success(let productId):
        print("恢复成功: \(productId)")
    case .failure(let error):
        print("恢复失败: \(error.localizedDescription)")
    }
}

// 5. 接收购买通知
NotificationCenter.default.addObserver(forName: .IAPPurchaseNotification, object: nil, queue: .main) { notif in
    guard let productId = notif.object as? String else { return }
    print("解锁内容: \(productId)")
}
*/
