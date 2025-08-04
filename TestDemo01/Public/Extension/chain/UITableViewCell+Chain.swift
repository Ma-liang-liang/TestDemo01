//
//  UITableViewCell+Chain.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UITableViewCell {
    @discardableResult
    func selectionStyle(_ selectionStyle: UITableViewCell.SelectionStyle) -> UITableViewCell {
        self.selectionStyle = selectionStyle
        return self
    }
    
    @discardableResult
    func backgroundView(_ backgroundView: UIView?) -> UITableViewCell {
        self.backgroundView = backgroundView
        return self
    }
 
}
