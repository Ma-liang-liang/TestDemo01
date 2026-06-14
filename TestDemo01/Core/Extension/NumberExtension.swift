//
//  NumberExtension.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/14.
//

import Foundation
import UIKit

public
extension Int {
    
    var cgFloat: CGFloat {
        CGFloat(self)
    }
    
    var double: Double {
        Double(self)
    }
    
    var px: CGFloat {
        UIScreen.scaleSize * cgFloat
    }
    
    var string: String {
        String(self)
    }
    
    var regularFont: UIFont {
        UIFont.systemFont(ofSize: cgFloat, weight: .regular)
    }
    
    var semiboldFont: UIFont {
        UIFont.systemFont(ofSize: cgFloat, weight: .semibold)
    }

    var mediumFont: UIFont {
        UIFont.systemFont(ofSize: cgFloat, weight: .medium)
    }

    var boldFont: UIFont {
        UIFont.systemFont(ofSize: cgFloat, weight: .bold)
    }
    
    var heavyFont: UIFont {
        UIFont.systemFont(ofSize: cgFloat, weight: .heavy)
    }
    
}

public
extension Double {
    
    var cgFloat: CGFloat {
        CGFloat(self)
    }
    
    var int: Int {
        Int(self)
    }
    
    var px: CGFloat {
        UIScreen.scaleSize * cgFloat
    }
    
    var twoDigitString: String {
        String(format: "%.2f", self)
    }
    
    var string: String {
        String(format: "%f", self)
    }
}

public
extension CGFloat {
    
    var int: Int {
        Int(self)
    }
    
    var double: Double {
        Double(self)
    }
    
    var px: CGFloat {
        UIScreen.scaleSize * self
    }
    
    var twoDigitString: String {
        String(format: "%.2f", self)
    }
    
    var string: String {
        String(format: "%f", self)
    }
   
}
