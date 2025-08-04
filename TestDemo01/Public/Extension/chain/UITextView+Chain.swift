//
//  UITextView+Extension.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UITextView {
    @discardableResult
    func cg_text(_ text: String) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult
    func cg_font(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func cg_textColor(_ color: UIColor) -> Self {
        self.textColor = color
        return self
    }
    
    @discardableResult
    func cg_textAlignment(_ alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
    
    @discardableResult
    func cg_attributedText(_ attributedText: NSAttributedString) -> Self {
        self.attributedText = attributedText
        return self
    }
    
    @discardableResult
    func cg_isEditable(_ isEditable: Bool) -> Self {
        self.isEditable = isEditable
        return self
    }
    
    @discardableResult
    func cg_isSelectable(_ isSelectable: Bool) -> Self {
        self.isSelectable = isSelectable
        return self
    }
    
    @discardableResult
    func cg_dataDetectorTypes(_ types: UIDataDetectorTypes) -> Self {
        self.dataDetectorTypes = types
        return self
    }
    
    @discardableResult
    func cg_allowsEditingTextAttributes(_ allows: Bool) -> Self {
        self.allowsEditingTextAttributes = allows
        return self
    }
    
    @discardableResult
    func cg_typingAttributes(_ attributes: [NSAttributedString.Key: Any]) -> Self {
        self.typingAttributes = attributes
        return self
    }
    
    @discardableResult
    func cg_delegate(_ delegate: UITextViewDelegate?) -> Self {
        self.delegate = delegate
        return self
    }
    
    @discardableResult
    func cg_keyboardType(_ type: UIKeyboardType) -> Self {
        self.keyboardType = type
        return self
    }
    
    @discardableResult
    func cg_returnKeyType(_ type: UIReturnKeyType) -> Self {
        self.returnKeyType = type
        return self
    }
    
    @discardableResult
    func cg_isSecureTextEntry(_ isSecure: Bool) -> Self {
        self.isSecureTextEntry = isSecure
        return self
    }
    
    @discardableResult
    func cg_textContainerInset(_ inset: UIEdgeInsets) -> Self {
        self.textContainerInset = inset
        return self
    }
    
    @discardableResult
    func cg_linkTextAttributes(_ attributes: [NSAttributedString.Key: Any]) -> Self {
        self.linkTextAttributes = attributes
        return self
    }
}
