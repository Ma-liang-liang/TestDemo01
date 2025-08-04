//
//  MessageCenter.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/26.
//

import UIKit
import Foundation

import Foundation

//// MARK: - 消息协议（所有自定义消息需实现）
//protocol MessageType {}
//
//// MARK: - 消息监听中心
//final class MessageCenter {
//     let table = NSMapTable<AnyObject, NSMutableDictionary>(
//        keyOptions: [.weakMemory, .objectPointerPersonality],
//        valueOptions: .strongMemory
//    )
//    private let queue = DispatchQueue(label: "com.message.center.queue", attributes: .concurrent)
//    
//    static let shared = MessageCenter()
//    private init() {}
//    
//    // MARK: - 添加监听
//    func addObserver<T: MessageType>(
//        _ observer: AnyObject,
//        messageType: T.Type,
//        handler: @escaping (T) -> Void
//    ) {
//        queue.async(flags: .barrier) { [weak self] in
//            let key = String(describing: messageType)
//            let wrapper = MessageWrapper(handler: handler)
//            
//            // 关联 DeallocWatcher（确保唯一性）
//            self?.associateDeallocWatcher(to: observer)
//            
//            guard let dict = self?.table.object(forKey: observer) else {
//                let newDict = NSMutableDictionary()
//                newDict[key] = [wrapper]
//                self?.table.setObject(newDict, forKey: observer)
//                return
//            }
//            
//            if let existing = dict[key] as? [MessageWrapper] {
//                dict[key] = existing + [wrapper]
//            } else {
//                dict[key] = [wrapper]
//            }
//        }
//    }
//    
//    // MARK: - 发送消息
//    func send<T: MessageType>(_ message: T, async: Bool = true) {
//        let key = String(describing: T.self)
//        let handlers = queue.sync { [weak self] () -> [MessageWrapper] in
//            guard let enumerator = self?.table.objectEnumerator() else { return [] }
//            
//            var allHandlers = [MessageWrapper]()
//            while let dict = enumerator.nextObject() as? NSMutableDictionary {
//                if let handlers = dict[key] as? [MessageWrapper] {
//                    allHandlers += handlers
//                }
//            }
//            return allHandlers
//        }
//        
//        let execution: () -> Void = {
//            handlers.forEach { wrapper in
//                if let handler = wrapper.handler as? (T) -> Void {
//                    handler(message)
//                }
//            }
//        }
//        
//        async ? DispatchQueue.main.async(execute: execution) : execution()
//    }
//    
//    // MARK: - 移除监听（非泛型方法，移除所有类型）
//    private func removeObserver(_ observer: AnyObject) {
//        queue.async(flags: .barrier) { [weak self] in
//            self?.table.removeObject(forKey: observer)
//        }
//    }
//    
//    // MARK: - 关联 DeallocWatcher
//    private func associateDeallocWatcher(to observer: AnyObject) {
//        if objc_getAssociatedObject(observer, &AssociatedKeys.deallocWatcherKey) == nil {
//            // 关键修复：闭包中使用 [weak observer]，避免强引用
//            let watcher = DeallocWatcher { [weak observer] in
//                guard let observer = observer else { return }
//                MessageCenter.shared.removeObserver(observer)
//            }
//            objc_setAssociatedObject(
//                observer,
//                &AssociatedKeys.deallocWatcherKey,
//                watcher,
//                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
//            )
//        }
//    }
//}
//
//// MARK: - 消息包装器
//private class MessageWrapper {
//    let handler: Any
//    
//    init<T>(handler: @escaping (T) -> Void) {
//        self.handler = handler
//    }
//    
//    
//    deinit {
//        print("deinit ===== \(type(of: self))")
//    }
//
//
//}
//
//// MARK: - Dealloc 监听器（修复循环引用）
//private class DeallocWatcher {
//    private let onDeinit: () -> Void
//    
//    init(onDeinit: @escaping () -> Void) {
//        self.onDeinit = onDeinit
//    }
//    
//    deinit {
//        onDeinit()
//        print("deinit ===== \(type(of: self))")
//    }
//}
//
//// MARK: - 关联对象键
//private struct AssociatedKeys {
//    static var deallocWatcherKey = "com.message.center.deallocWatcherKey"
//}


import Foundation

// MARK: - 消息协议
protocol MessageType {}

// MARK: - 消息监听中心
final class MessageCenter {
    private let table = NSMapTable<AnyObject, NSMutableDictionary>(
        keyOptions: [.weakMemory, .objectPointerPersonality],
        valueOptions: .strongMemory
    )
    private let queue = DispatchQueue(label: "com.message.center.queue", attributes: .concurrent)
    
    static let shared = MessageCenter()
    private init() {}
    
    // MARK: - 添加监听（带自动清理）
    func addObserver<T: MessageType>(
        _ observer: AnyObject,
        messageType: T.Type,
        handler: @escaping (T) -> Void
    ) {
        queue.async(flags: .barrier) { [weak self] in
            let key = String(describing: messageType)
            let wrapper = MessageWrapper(observer: observer, handler: handler)
            
            // 自动清理无效监听（观察者已释放但残留的字典）
            self?.cleanupStaleEntries(forKey: key)
            
            guard let dict = self?.table.object(forKey: observer) else {
                let newDict = NSMutableDictionary()
                newDict[key] = NSMutableArray(array: [wrapper])
                self?.table.setObject(newDict, forKey: observer)
                return
            }
            
            if let existing = dict[key] as? NSMutableArray {
                existing.add(wrapper)
            } else {
                dict[key] = NSMutableArray(array: [wrapper])
            }
        }
    }
    
    // MARK: - 发送消息（带自动过滤）
    func send<T: MessageType>(_ message: T, async: Bool = true) {
        let key = String(describing: T.self)
        let handlers = queue.sync { [weak self] () -> [MessageWrapper] in
            guard let enumerator = self?.table.objectEnumerator() else { return [] }
            
            var validHandlers = [MessageWrapper]()
            var staleHandlers = [MessageWrapper]()
            
            // 遍历所有观察者字典
            while let dict = enumerator.nextObject() as? NSMutableDictionary {
                guard let wrappers = dict[key] as? NSMutableArray else { continue }
                
                // 分离有效和失效的监听
                let (valid, stale) = wrappers.compactMap { $0 as? MessageWrapper }
                    .reduce(into: (valid: [MessageWrapper](), stale: [MessageWrapper]())) { res, wrapper in
                        if wrapper.observer != nil {
                            res.valid.append(wrapper)
                        } else {
                            res.stale.append(wrapper)
                        }
                    }
                
                validHandlers += valid
                staleHandlers += stale
                
                // 自动移除失效监听
                if !stale.isEmpty {
                    wrappers.removeObjects(in: stale)
                }
                
                // 若当前类型监听为空则移除键
                if wrappers.count == 0 {
                    dict.removeObject(forKey: key)
                }
            }
            
            // 异步清理残留的空字典
            self?.cleanupEmptyDictionaries()
            return validHandlers
        }
        
        // 执行有效回调
        let execution = { handlers.forEach { $0.invoke(message: message) } }
        async ? DispatchQueue.main.async(execute: execution) : execution()
    }
    
    // MARK: - 精准移除监听
    func removeObserver<T: MessageType>(_ observer: AnyObject, messageType: T.Type? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            guard let dict = self?.table.object(forKey: observer) else { return }
            
            if let type = messageType {
                let key = String(describing: type)
                dict.removeObject(forKey: key)
                
                // 若字典为空则完全移除观察者
                if dict.count == 0 {
                    self?.table.removeObject(forKey: observer)
                }
            } else {
                // 移除所有监听
                dict.removeAllObjects()
                self?.table.removeObject(forKey: observer)
            }
        }
    }
    
    // MARK: - 自动清理机制
    private func cleanupStaleEntries(forKey key: String) {
        guard let enumerator = table.objectEnumerator() else { return }
        
        while let dict = enumerator.nextObject() as? NSMutableDictionary {
            guard let wrappers = dict[key] as? NSMutableArray else { continue }
            
            // 过滤出observer存在的wrapper
            let valid = wrappers.compactMap { $0 as? MessageWrapper }
                .filter { $0.observer != nil }
            
            if valid.isEmpty {
                dict.removeObject(forKey: key)
            } else {
                wrappers.setArray(valid)
            }
        }
    }
    
    private func cleanupEmptyDictionaries() {
        let keysToRemove = table.keyEnumerator().compactMap { $0 as? AnyObject }
            .filter { table.object(forKey: $0).map { ($0 as! NSDictionary).count == 0 } ?? false }
        
        keysToRemove.forEach { table.removeObject(forKey: $0) }
    }
}

// MARK: - 消息包装器
private class MessageWrapper {
    weak var observer: AnyObject?
    private let handler: Any
    
    init<T>(observer: AnyObject, handler: @escaping (T) -> Void) {
        self.observer = observer
        self.handler = handler
    }
    
    func invoke<T>(message: T) {
        guard let handler = handler as? (T) -> Void else { return }
        handler(message)
    }
    
    deinit {
        print("MessageWrapper deinit")
    }
}
