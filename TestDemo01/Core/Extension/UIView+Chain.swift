//
//  UIView+Extension.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UIView {
    
    @discardableResult
    func cg_setFrame(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) -> Self {
        var frame = self.frame
        if let x = x {
            frame.origin.x = x
        }
        if let y = y {
            frame.origin.y = y
        }
        if let width = width {
            frame.size.width = width
        }
        if let height = height {
            frame.size.height = height
        }
        self.frame = frame
        return self
    }
    
    @discardableResult
    func cg_setOrigin(x: CGFloat? = nil, y: CGFloat? = nil) -> Self {
        return cg_setFrame(x: x, y: y)
    }
    
    @discardableResult
    func cg_setSize(width: CGFloat? = nil, height: CGFloat? = nil) -> Self {
        return cg_setFrame(width: width, height: height)
    }
    
    @discardableResult
    func cg_setCenter(x: CGFloat? = nil, y: CGFloat? = nil) -> Self {
        var center = self.center
        if let x = x {
            center.x = x
        }
        if let y = y {
            center.y = y
        }
        self.center = center
        return self
    }
    
    @discardableResult
    func cg_setCenterX(_ centerX: CGFloat) -> Self {
        var center = self.center
        center.x = centerX
        self.center = center
        return self
    }
    
    @discardableResult
    func cg_setCenterY(_ centerY: CGFloat) -> Self {
        var center = self.center
        center.y = centerY
        self.center = center
        return self
    }
    
    @discardableResult
    func cg_setTop(_ top: CGFloat) -> Self {
        return cg_setFrame(y: top)
    }
    
    @discardableResult
    func cg_setLeft(_ left: CGFloat) -> Self {
        return cg_setFrame(x: left)
    }
    
    @discardableResult
    func cg_setBottom(_ bottom: CGFloat) -> Self {
        if let superview = superview {
            return cg_setFrame(y: superview.frame.height - bottom - frame.height)
        } else {
            return self
        }
    }
    
    @discardableResult
    func cg_setRight(_ right: CGFloat) -> Self {
        if let superview = superview {
            return cg_setFrame(x: superview.frame.width - right - frame.width)
        } else {
            return self
        }
    }
}

public
extension UIView {
    
    @discardableResult
    func cg_setBackgroundColor(_ color: UIColor) -> Self {
        backgroundColor = color
        return self
    }
    
    @discardableResult
    func cg_setAlpha(_ alpha: CGFloat) -> Self {
        self.alpha = alpha
        return self
    }
    
    @discardableResult
    func cg_setHidden(_ hidden: Bool) -> Self {
        self.isHidden = hidden
        return self
    }
    
    @discardableResult
    func cg_setCornerRadius(_ radius: CGFloat) -> Self {
        layer.cornerRadius = radius
        layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    func cg_setBorder(width: CGFloat, color: UIColor) -> Self {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_setShadow(radius: CGFloat, opacity: Float, offset: CGSize, color: UIColor) -> Self {
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_addSubviews(_ subviews: UIView...) -> Self {
        subviews.forEach { addSubview($0) }
        return self
    }
    
    @discardableResult
    func cg_removeSubviews() -> Self {
        subviews.forEach { $0.removeFromSuperview() }
        return self
    }
    
    @discardableResult
    func cg_bringToFront() -> Self {
        superview?.bringSubviewToFront(self)
        return self
    }
    
    @discardableResult
    func cg_sendToBack() -> Self {
        superview?.sendSubviewToBack(self)
        return self
    }
    
    @discardableResult
    func cg_setTag(_ tag: Int) -> Self {
        self.tag = tag
        return self
    }
    
    @discardableResult
    func cg_setUserInteractionEnabled(_ enabled: Bool) -> Self {
        isUserInteractionEnabled = enabled
        return self
    }
    
    @discardableResult
    func cg_setClipsToBounds(_ clipsToBounds: Bool) -> Self {
        self.clipsToBounds = clipsToBounds
        return self
    }
    
    @discardableResult
    func cg_tintColor(_ color: UIColor) -> Self {
        self.tintColor = color
        return self
    }
}

public
extension UIView {
    
    @discardableResult
    func cg_layer_cornerRadius(_ radius: CGFloat) -> Self {
        layer.cornerRadius = radius
        return self
    }
    
    @discardableResult
    func cg_layer_borderWidth(_ width: CGFloat) -> Self {
        layer.borderWidth = width
        return self
    }
    
    @discardableResult
    func cg_layer_borderColor(_ color: UIColor) -> Self {
        layer.borderColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_layer_shadowColor(_ color: UIColor) -> Self {
        layer.shadowColor = color.cgColor
        return self
    }
    
    @discardableResult
    func cg_layer_shadowOpacity(_ opacity: Float) -> Self {
        layer.shadowOpacity = opacity
        return self
    }
    
    @discardableResult
    func cg_layer_shadowOffset(_ offset: CGSize) -> Self {
        layer.shadowOffset = offset
        return self
    }
    
    @discardableResult
    func cg_layer_shadowRadius(_ radius: CGFloat) -> Self {
        layer.shadowRadius = radius
        return self
    }
    
    @discardableResult
    func cg_layer_masksToBounds(_ masksToBounds: Bool) -> Self {
        layer.masksToBounds = masksToBounds
        return self
    }
}
