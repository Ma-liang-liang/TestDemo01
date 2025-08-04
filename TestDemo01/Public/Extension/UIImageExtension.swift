//
//  UIImageExtension.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/15.
//

import UIKit

extension UIImage {
    
    /// 按照指定的宽度，按照原图比例重新绘制出一张完整的图片
    /// - Parameter targetWidth: 目标宽度
    /// - Returns: 重新绘制后的图片
    func resized(toWidth targetWidth: CGFloat) -> UIImage? {
        // 计算目标高度，保持原图比例
        let scaleFactor = targetWidth / size.width
        let targetHeight = size.height * scaleFactor
        
        // 设置新的绘制尺寸
        let newSize = CGSize(width: targetWidth, height: targetHeight)
        
        // 开始绘制
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    
}
