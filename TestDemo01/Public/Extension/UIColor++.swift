//
//  UIColor++.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/5.
//

import UIKit
import SwifterSwift


extension UIColor {
    
    static func hex(hexString: String, alpha: CGFloat = 1) -> UIColor {
        UIColor(hexString: hexString, transparency: alpha) ?? .red
    }
    
    static var themeColor: UIColor {
        UIColor.hex(hexString: "#11A560")
    }
    
    static func black_323232_color(alpha: CGFloat = 1.0) -> UIColor {
        UIColor.hex(hexString: "#323232", alpha: alpha)
    }
        
    static var gray_9E9E9E_color: UIColor {
        UIColor.hex(hexString: "#9E9E9E")
    }
    
    
}
