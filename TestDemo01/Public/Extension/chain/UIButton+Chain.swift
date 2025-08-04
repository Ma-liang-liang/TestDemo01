//
//  UIButton+Extension.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UIButton {
   
    @discardableResult
    func cg_setTitle(_ title: String?, for state: UIControl.State = .normal) -> Self {
        setTitle(title, for: state)
        return self
    }
    
    @discardableResult
    func cg_setTitleColor(_ color: UIColor?, for state: UIControl.State = .normal) -> Self {
        setTitleColor(color, for: state)
        return self
    }
    
    @discardableResult
    func cg_setTitleFont(_ font: UIFont?) -> Self {
        if let font {
            titleLabel?.font = font
        }
        return self
    }
    
    @discardableResult
    func cg_setAttributedTitle(_ attributedTitle: NSAttributedString?, for state: UIControl.State = .normal) -> Self {
        setAttributedTitle(attributedTitle, for: state)
        return self
    }
    
    @discardableResult
    func cg_setImage(_ image: UIImage?, for state: UIControl.State = .normal) -> Self {
        setImage(image, for: state)
        return self
    }
    
    @discardableResult
    func cg_setBackgroundImage(_ image: UIImage?, for state: UIControl.State = .normal) -> Self {
        setBackgroundImage(image, for: state)
        return self
    }
    
    @discardableResult
    func cg_addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event = .touchUpInside) -> Self {
        addTarget(target, action: action, for: controlEvents)
        return self
    }
    
    @discardableResult
    func cg_setEnabled(_ enabled: Bool) -> Self {
        isEnabled = enabled
        return self
    }
    
    @discardableResult
    func cg_setContentInsets(_ insets: UIEdgeInsets) -> Self {
        if #available(iOS 15.0, *) {
            var config = configuration ?? UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
            config.baseBackgroundColor = .clear
            configuration = config
        } else {
            contentEdgeInsets = insets
        }
        return self
    }
  
}
