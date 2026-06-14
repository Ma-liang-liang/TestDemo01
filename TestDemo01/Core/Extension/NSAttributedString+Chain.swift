//
//  NSAttributedString+Chain.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import Foundation
import UIKit

@resultBuilder
public struct AttributedStringBuilder {
    public static func buildBlock(_ components: NSAttributedString...) -> NSAttributedString {
        let result = NSMutableAttributedString()
        components.forEach { result.append($0) }
        return result
    }
    
    public static func buildExpression(_ expression: NSAttributedString) -> NSAttributedString {
        expression
    }
    
    public static func buildLimitedAvailability(_ component: NSAttributedString) -> NSAttributedString {
        component
    }
    
    public static func buildOptional(_ component: NSAttributedString?) -> NSAttributedString {
        component ?? NSAttributedString()
    }
    
    public static func buildEither(first component: NSAttributedString) -> NSAttributedString {
        component
    }
    
    public static func buildEither(second component: NSAttributedString) -> NSAttributedString {
        component
    }
    
    public static func buildArray(_ components: [NSAttributedString]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        components.forEach { result.append($0) }
        return result
    }
}

public extension NSAttributedString {
    
    convenience init(@AttributedStringBuilder builder: () -> NSAttributedString) {
        self.init(attributedString: builder())
    }
}

public extension NSAttributedString {
    
    var cg_mutableAttributedString: NSMutableAttributedString {
        NSMutableAttributedString(attributedString: self)
    }
    
    func cg_range(of string: String) -> NSRange {
        return (self.string as NSString).range(of: string)
    }
    
    func cg_rangeOfAll() -> NSRange {
        return NSRange(location: 0, length: string.count)
    }

    /// Gets the original paragraph style
    var cg_mutableParagraphStyle: NSMutableParagraphStyle {
        var range = cg_rangeOfAll()
        // has a bug
        if range.length == 0 { return NSMutableParagraphStyle() }
        let style = attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: &range) as? NSMutableParagraphStyle
        return style ?? NSMutableParagraphStyle()
    }
    
    static func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSMutableAttributedString {
        let combinedString = NSMutableAttributedString(attributedString: lhs)
        combinedString.append(rhs)
        return combinedString
    }

}

public extension NSMutableAttributedString {
    
    @discardableResult
    func cg_setAttribute(_ key: NSAttributedString.Key, value: Any, ranges: [NSRange]? = nil) -> Self {

        guard let ranges = ranges else {
            addAttribute(key, value: value, range: cg_rangeOfAll())
            return self
        }
        if ranges.isEmpty {
             addAttribute(key, value: value, range: cg_rangeOfAll())
            return self
        }
        for range in ranges {
            addAttribute(key, value: value, range: range)
        }
        return self
    }
        
    @discardableResult
    func cg_setFont(_ font: UIFont, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.font, value: font, ranges: ranges)
    }
    
    @discardableResult
    func cg_setColor(_ color: UIColor, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.foregroundColor, value: color, ranges: ranges)
    }
    
    @discardableResult
    func cg_setBackgroundColor(_ color: UIColor, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.backgroundColor, value: color, ranges: ranges)
    }
    
    @discardableResult
    func cg_setLink(_ url: String, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.link, value: url, ranges: ranges)
    }
    
    @discardableResult
    func cg_setUnderline(style: NSUnderlineStyle = .single, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.underlineStyle, value: style.rawValue, ranges: ranges)
    }
    
    @discardableResult
    func cg_setUnderlineColor(color: UIColor, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.underlineColor, value: color, ranges: ranges)
    }
    
    @discardableResult
    func cg_setStrikethrough(style: NSUnderlineStyle = .single, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.strikethroughStyle, value: style.rawValue, ranges: ranges)
    }
    
    @discardableResult
    func cg_setStrikethroughColor(color: UIColor, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.strikethroughColor, value: color, ranges: ranges)
    }
    
    @discardableResult
    func cg_setParagraphStyle(_ style: NSParagraphStyle, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.paragraphStyle, value: style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setKern(_ kern: CGFloat, ranges: [NSRange]? = nil) -> Self {
        cg_setAttribute(.kern, value: kern, ranges: ranges)
    }
    
    @discardableResult
    func cg_setParagraphSpacing(_ spacing: CGFloat, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
            .cg_setParagraphSpacing(spacing)
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setLineSpacing(_ spacing: CGFloat, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
            .cg_setLineSpacing(spacing)
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setFirstLineHeadIndent(_ indent: CGFloat, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
            .cg_setFirstLineHeadIndent(indent)
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setHeadIndent(_ indent: CGFloat, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
            .cg_setHeadIndent(indent)
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setTailIndent(_ indent: CGFloat, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
            .cg_setTailIndent(indent)
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setAlignment(_ alignment: NSTextAlignment, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
            .cg_setAlignment(alignment)
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    @discardableResult
    func cg_setLineBreakMode(_ lineBreakMode: NSLineBreakMode, ranges: [NSRange]? = nil) -> Self {
        let style = cg_mutableParagraphStyle
        style.lineBreakMode = lineBreakMode
        return cg_setParagraphStyle(style, ranges: ranges)
    }
    
    var cg_attributedString: NSAttributedString {
        NSAttributedString(attributedString: self)
    }
}

public extension String {
    
    var cg_attributedString: NSAttributedString {
        NSAttributedString(string: self)
    }
    
    var cg_mutableAttributedString: NSMutableAttributedString {
        NSMutableAttributedString(string: self)
    }
    
    func cg_rangeOfAll() -> NSRange {
        return NSRange(location: 0, length: count)
    }
        
    func cg_nsRanges(of string: String, option: NSString.CompareOptions = .literal) -> [NSRange] {
        var ranges: [NSRange] = []
        var startIndex = self.startIndex
        while let range = self[startIndex...].range(of: string, options: option) {
            ranges.append(NSRange(range, in: self))
            startIndex = range.upperBound
        }
        return ranges
    }
    
    func cg_ranges(of string: String, option: NSString.CompareOptions = .literal) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var startIndex = self.startIndex
        while let range = self[startIndex...].range(of: string, options: option) {
            ranges.append(range)
            startIndex = range.upperBound
        }
        return ranges
    }
    
    func cg_parseHtmlString(color: UIColor, font: UIFont,
                            linkColor: UIColor, linkFont: UIFont) -> NSAttributedString {
        
        guard let data = data(using: .utf8) else {
            return NSAttributedString()
        }
           
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
            
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: linkColor,
                .font: linkFont
            ]
            
            let otherAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: font
            ]
            attributedString.beginEditing()
            attributedString.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedString.length), options: []) { (value, range, _) in
                if let url = value as? URL {
                    attributedString.addAttribute(.link, value: url, range: range)
                    attributedString.addAttributes(linkAttributes, range: range)
                } else {
                    attributedString.addAttributes(otherAttributes, range: range)
                }
            }
            attributedString.endEditing()
            return attributedString
        } catch {
            print("parse html string error: \n \(error)")
            return NSAttributedString()
        }
        
    }
    
    /// Highlights all occurrences of a search string within the original string
    /// - Parameters:
    ///   - searchText: The text to search for and highlight
    ///   - highlightColor: The color to use for highlighting (default is system yellow)
    ///   - highlightFont: The font for highlighted text (nil keeps original font)
    ///   - defaultColor: The color for unmatched text (default is black)
    ///   - defaultFont: The font for unmatched text (default is system font of size 17)
    ///   - caseSensitive: Whether the search should be case sensitive (default is false)
    /// - Returns: An attributed string with highlighted matches
    func cg_highlight(
        _ searchText: String,
        highlightColor: UIColor = .systemYellow,
        highlightFont: UIFont? = nil,
        defaultColor: UIColor = .black,
        defaultFont: UIFont = UIFont.systemFont(ofSize: 17),
        caseSensitive: Bool = false
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: self,
            attributes: [
                .foregroundColor: defaultColor,
                .font: defaultFont
            ]
        )
        
        // If search text is empty, return string with default styling
        guard !searchText.isEmpty else {
            return attributedString
        }
        
        let options: String.CompareOptions = caseSensitive ? [] : .caseInsensitive
        var searchRange = Range(uncheckedBounds: (lower: self.startIndex, upper: self.endIndex))
        
        while let foundRange = self.range(
            of: searchText,
            options: options,
            range: searchRange,
            locale: nil
        ) {
            let nsRange = NSRange(foundRange, in: self)
            
            // Apply highlight color
            attributedString.addAttribute(
                .foregroundColor,
                value: highlightColor,
                range: nsRange
            )
            
            // Apply highlight font if specified
            if let highlightFont = highlightFont {
                attributedString.addAttribute(
                    .font,
                    value: highlightFont,
                    range: nsRange
                )
            }
            
            // Update search range to continue searching after this match
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: self.endIndex))
        }
        
        return attributedString
    }
    
}

public extension UIImage {
  
    func cg_setAttributedString(bounds rect: CGRect? = nil) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = self
        if let rect { 
            attachment.bounds = rect
        }
        return NSAttributedString(attachment: attachment)
    }
}

public extension NSMutableParagraphStyle {
    @discardableResult
    func cg_setAlignment(_ alignment: NSTextAlignment) -> Self {
        self.alignment = alignment
        return self
    }

    @discardableResult
    func cg_setLineSpacing(_ lineSpacing: CGFloat) -> Self {
        self.lineSpacing = lineSpacing
        return self
    }

    @discardableResult
    func cg_setParagraphSpacing(_ paragraphSpacing: CGFloat) -> Self {
        self.paragraphSpacing = paragraphSpacing
        return self
    }

    @discardableResult
    func cg_setFirstLineHeadIndent(_ firstLineHeadIndent: CGFloat) -> Self {
        self.firstLineHeadIndent = firstLineHeadIndent
        return self
    }

    @discardableResult
    func cg_setHeadIndent(_ headIndent: CGFloat) -> Self {
        self.headIndent = headIndent
        return self
    }

    @discardableResult
    func cg_setTailIndent(_ tailIndent: CGFloat) -> Self {
        self.tailIndent = tailIndent
        return self
    }

    @discardableResult
    func cg_setLineBreakMode(_ lineBreakMode: NSLineBreakMode) -> Self {
        self.lineBreakMode = lineBreakMode
        return self
    }

    @discardableResult
    func cg_setMinimumLineHeight(_ minimumLineHeight: CGFloat) -> Self {
        self.minimumLineHeight = minimumLineHeight
        return self
    }

    @discardableResult
    func cg_setMaximumLineHeight(_ maximumLineHeight: CGFloat) -> Self {
        self.maximumLineHeight = maximumLineHeight
        return self
    }

    @discardableResult
    func cg_setLineHeightMultiple(_ lineHeightMultiple: CGFloat) -> Self {
        self.lineHeightMultiple = lineHeightMultiple
        return self
    }

    @discardableResult
    func cg_setParagraphSpacingBefore(_ paragraphSpacingBefore: CGFloat) -> Self {
        self.paragraphSpacingBefore = paragraphSpacingBefore
        return self
    }

    @discardableResult
    func cg_setBaseWritingDirection(_ baseWritingDirection: NSWritingDirection) -> Self {
        self.baseWritingDirection = baseWritingDirection
        return self
    }
}
