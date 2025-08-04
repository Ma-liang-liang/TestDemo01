//
//  SKNotificationProtocol.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/6.
//

import UIKit

protocol SKNotificationProtocol: AnyObject {

    func addNotification(name: String)
    
    func onReceiveNotification(notifi: Notification)
    
}

extension SKNotificationProtocol {
    
    func addNotification(name: String) {

    }
    
    func onNotification(name: String, _ object: Any? = nil) {
        
    }
}
