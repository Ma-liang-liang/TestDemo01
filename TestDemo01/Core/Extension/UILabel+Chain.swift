//
//  UILabel+Extension.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UILabel {
    
    @discardableResult
    func cg_setText(_ text: String?) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult
    func cg_setTextColor(_ color: UIColor) -> Self {
        textColor = color
        return self
    }
    
    @discardableResult
    func cg_setTextAlignment(_ alignment: NSTextAlignment) -> Self {
        textAlignment = alignment
        return self
    }
    
    @discardableResult
    func cg_setFont(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func cg_setNumberOfLines(_ numberOfLines: Int) -> Self {
        self.numberOfLines = numberOfLines
        return self
    }
    
    @discardableResult
    func cg_setLineBreakMode(_ mode: NSLineBreakMode) -> Self {
        self.lineBreakMode = mode
        return self
    }
    
    @discardableResult
    func cg_setAttributedText(_ text: NSAttributedString?) -> Self {
        attributedText = text
        return self
    }
    
    @discardableResult
    func cg_setShadowColor(_ color: UIColor?) -> Self {
        shadowColor = color
        return self
    }
    
    @discardableResult
    func cg_setShadowOffset(_ offset: CGSize) -> Self {
        shadowOffset = offset
        return self
    }
    
    @discardableResult
    func cg_setHighlightedTextColor(_ color: UIColor?) -> Self {
        highlightedTextColor = color
        return self
    }
    
    @discardableResult
    func cg_setAdjustsFontSizeToFitWidth(_ flag: Bool) -> Self {
        adjustsFontSizeToFitWidth = flag
        return self
    }
    
    @discardableResult
    func cg_setMinimumScaleFactor(_ factor: CGFloat) -> Self {
        minimumScaleFactor = factor
        return self
    }
    
    @discardableResult
    func cg_setBaselineAdjustment(_ adjustment: UIBaselineAdjustment) -> Self {
        baselineAdjustment = adjustment
        return self
    }
}
