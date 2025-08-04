//
//  TextTappedLabel.swift
//  koin_ui
//
//  Created by sunshine on 2024/1/22.
//

import UIKit

open class TextTappedLabel: UILabel {
    public typealias TappedTextHandler = (String) -> Void
    
    public var tappedTextHandler: TappedTextHandler?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTapGesture()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTapGesture()
    }
    
    private func setupTapGesture() {
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = attributedText else { return }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let location = gesture.location(in: self)
        let textOffset = CGPoint(x: location.x - textContainer.lineFragmentPadding, y: location.y - textContainer.lineFragmentPadding)
        
        let characterIndex = layoutManager.characterIndex(for: textOffset, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { (attributes, range, _) in
            if let tappedTextHandler = tappedTextHandler,
               let tappedString = attributedText.attributedSubstring(from: range).string as String?,
               NSLocationInRange(characterIndex, range) {
                tappedTextHandler(tappedString)
            }
        }
    }
}
