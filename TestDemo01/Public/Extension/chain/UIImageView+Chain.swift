//
//  UIImageView+Extension.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UIImageView {
    @discardableResult
    func cg_setImage(_ image: UIImage?) -> Self {
        self.image = image
        return self
    }
    
    @discardableResult
    func cg_setContentMode(_ mode: UIView.ContentMode) -> Self {
        contentMode = mode
        return self
    }
    
    @discardableResult
    func cg_setTintColor(_ color: UIColor) -> Self {
        tintColor = color
        return self
    }
 
}
