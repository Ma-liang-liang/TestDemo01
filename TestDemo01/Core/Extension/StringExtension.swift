//
//  StringExtension.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/12.
//

import UIKit

extension String {
    /// 计算文本高度（固定宽度）
    /// - Parameters:
    ///   - width: 限制宽度
    ///   - font: 字体
    /// - Returns: 文本高度
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect,
                                           options: .usesLineFragmentOrigin,
                                           attributes: [.font: font],
                                           context: nil)
        return ceil(boundingBox.height)
    }
    
    /// 计算文本宽度（固定高度）
    /// - Parameters:
    ///   - height: 限制高度
    ///   - font: 字体
    /// - Returns: 文本宽度
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect,
                                           options: .usesLineFragmentOrigin,
                                           attributes: [.font: font],
                                           context: nil)
        return ceil(boundingBox.width)
    }
    
    /// 计算文本尺寸（有最大宽高限制）
    /// - Parameters:
    ///   - size: 限制尺寸
    ///   - font: 字体
    /// - Returns: 文本尺寸
    func size(withConstrainedSize size: CGSize, font: UIFont) -> CGSize {
        let boundingBox = self.boundingRect(with: size,
                                           options: .usesLineFragmentOrigin,
                                           attributes: [.font: font],
                                           context: nil)
        return CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height))
    }
}
