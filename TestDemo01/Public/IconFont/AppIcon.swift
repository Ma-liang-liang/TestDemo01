//
//  AppIcon.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/25.
//

import UIKit

final class IconFontManager {
    // MARK: - 内存优化配置
    private static var cache: NSCache<NSString, UIImage> = {
        let ch = NSCache<NSString, UIImage>()
        ch.countLimit = 100
        return ch
    }()
    
    private static var registered = false
    
    // MARK: - 字体注册（App启动时调用）
    static func registerFont() {
        guard !registered else { return }
        DispatchQueue.global().async {
            guard let fontURL = Bundle.main.url(forResource: "iconfont", withExtension: "ttf"),
                  let fontData = try? Data(contentsOf: fontURL),
                  let provider = CGDataProvider(data: fontData as CFData),
                  let font = CGFont(provider) else {
                fatalError("Failed to load iconfont")
            }
            
            var error: Unmanaged<CFError>?
            guard CTFontManagerRegisterGraphicsFont(font, &error) else {
                print("Font registration failed: \(error?.takeRetainedValue().localizedDescription ?? "")")
                return
            }
            self.registered = true
        }
    }
    
    // MARK: - 核心方法（内存优化版）
    static func icon(_ unicode: String,
                     size: CGFloat,
                     color: UIColor = .black,
                     backgroundColor: UIColor = .clear) -> UIImage? {
        // 1. 检查缓存
        let cacheKey = "\(unicode)_\(size)_\(color.hex)_\(backgroundColor.hex)" as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // 2. 安全检查
        guard registered else {
            registerFont()
            return nil
        }
        
        // 3. 创建属性字符串
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "iconfont", size: size) ?? .systemFont(ofSize: size),
            .foregroundColor: color,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // 4. 渲染图像（优化过的尺寸计算）
        let renderSize = CGSize(width: size, height: size)
        let image = UIGraphicsImageRenderer(size: renderSize).image { context in
            unicode.draw(
                in: CGRect(origin: .zero, size: renderSize),
                withAttributes: attributes
            )
        }
        
        // 5. 缓存结果
        cache.setObject(image, forKey: cacheKey)
        return image
    }
    
    // 使用 CGBitmapContext 直接生成位图（避免 UIGraphics 开销）
    private static func renderBitmap(_ unicode: String,
                                     size: CGFloat,
                                     color: UIColor) -> UIImage? {
        let scale = UIScreen.main.scale
        let pixelSize = Int(size * scale)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: pixelSize * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        // 矢量绘制
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "iconfont", size: size) ?? UIFont.systemFont(ofSize: size),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: unicode, attributes: attrs)
        let line = CTLineCreateWithAttributedString(str)
        
        context.textPosition = .zero
        CTLineDraw(line, context)
        
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
    
    // MARK: - 清理缓存（内存紧张时调用）
    static func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - 辅助扩展
private extension UIColor {
    var hex: String {
        guard let components = cgColor.components, components.count >= 3 else { return "" }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - 安全枚举封装（避免硬编码）
enum AppIcon: String {
   
    case arrow_left = "\u{e685}"
    
    case search = "\u{e67d}"
    
    case close = "\u{e669}"
    
    case refresh = "\u{e67b}"
    
    func image(size: CGFloat = 24, color: UIColor = .black) -> UIImage? {
        IconFontManager.icon(rawValue, size: size, color: color)
    }
}

extension UIImage {
    
    static func appIconImage(appIcon: AppIcon, size: CGFloat = 24, color: UIColor = .black) -> UIImage? {
         appIcon.image(size: size, color: color)
    }
    
}
