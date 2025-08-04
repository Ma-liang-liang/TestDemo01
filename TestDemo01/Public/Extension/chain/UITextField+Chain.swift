//
//  UITextField+Extension.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit


public
extension UITextField {
   
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
    func cg_setPlaceholder(_ placeholder: String?) -> Self {
        self.placeholder = placeholder
        return self
    }
    
    @discardableResult
    func cg_setBorderStyle(_ style: UITextField.BorderStyle) -> Self {
        borderStyle = style
        return self
    }
    
    @discardableResult
    func cg_setDelegate(_ delegate: UITextFieldDelegate?) -> Self {
        self.delegate = delegate
        return self
    }
    
    @discardableResult
    func cg_setKeyboardType(_ type: UIKeyboardType) -> Self {
        keyboardType = type
        return self
    }
    
    @discardableResult
    func cg_setReturnKeyType(_ type: UIReturnKeyType) -> Self {
        returnKeyType = type
        return self
    }
    
    @discardableResult
    func cg_setAutocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
        autocapitalizationType = type
        return self
    }
    
    @discardableResult
    func cg_setAutocorrectionType(_ type: UITextAutocorrectionType) -> Self {
        autocorrectionType = type
        return self
    }
    
    
    func cg_setIsSecureTextEntry(_ isSecure: Bool) -> Self {
        isSecureTextEntry = isSecure
        return self
    }
}

class TextFieldDelegate: NSObject, UITextFieldDelegate {
    var shouldBeginEditing: ((UITextField) -> Bool)?
    var didBeginEditing: ((UITextField) -> Void)?
    var shouldEndEditing: ((UITextField) -> Bool)?
    var didEndEditing: ((UITextField) -> Void)?
    var shouldChangeCharacters: ((UITextField, NSRange, String) -> Bool)?
    var shouldClear: ((UITextField) -> Bool)?
    var shouldReturn: ((UITextField) -> Bool)?
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return shouldBeginEditing?(textField) ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?(textField)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldEndEditing?(textField) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        didEndEditing?(textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldChangeCharacters?(textField, range, string) ?? true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return shouldClear?(textField) ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return shouldReturn?(textField) ?? true
    }
}

