//
//  CALayer+Chain.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension CALayer {
   
    @discardableResult
    func cg_setBackgroundColor(_ color: UIColor) -> Self {
        backgroundColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_setCornerRadius(_ radius: CGFloat) -> Self {
        cornerRadius = radius
        masksToBounds = true
        return self
    }
    
    @discardableResult
    func cg_setBorderWidth(_ width: CGFloat) -> Self {
        borderWidth = width
        return self
    }
    
    @discardableResult
    func cg_setBorderColor(_ color: UIColor) -> Self {
        borderColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_setShadowColor(_ color: UIColor) -> Self {
        shadowColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_setShadowOpacity(_ opacity: Float) -> Self {
        shadowOpacity = opacity
        return self
    }
    
    @discardableResult
    func cg_setShadowRadius(_ radius: CGFloat) -> Self {
        shadowRadius = radius
        return self
    }
    
    @discardableResult
    func cg_setShadowOffset(_ offset: CGSize) -> Self {
        shadowOffset = offset
        return self
    }
}
