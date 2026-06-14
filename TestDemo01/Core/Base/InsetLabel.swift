//
//  InsetLabel.swift
//  sufinc_credit_card_module
//
//  Created by sunshine on 2023/6/8.
//

import UIKit
 

public class InsetLabel: UILabel {

   public var textInsets: UIEdgeInsets = .zero {
        didSet {
            setNeedsDisplay()
        }
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
       
        let insets = textInsets
        var rect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        rect.origin.x    -= insets.left
        rect.origin.y    -= insets.top
        rect.size.width  += (insets.left + insets.right)
        rect.size.height += (insets.top + insets.bottom)
        return rect
    }

}
