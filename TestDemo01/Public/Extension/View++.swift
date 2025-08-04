//
//  View++.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/25.
//

import SwiftUI

extension Color {
    /// 通过 HEX 字符串创建 Color（支持格式：#RGB / #ARGB / #RRGGBB / #AARRGGBB）
    /// - Parameters:
    ///   - hex: HEX 字符串（如 "#FF5733"）
    ///   - alpha: 可选透明度覆盖（0.0 - 1.0）
    init(hex: String, alpha: CGFloat? = nil) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let a: CGFloat
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            a = alpha ?? 1.0
            r = CGFloat((rgb >> 8) & 0xF) / 15.0
            g = CGFloat((rgb >> 4) & 0xF) / 15.0
            b = CGFloat(rgb & 0xF) / 15.0
        case 4: // ARGB (16-bit)
            a = alpha ?? CGFloat((rgb >> 12) & 0xF) / 15.0
            r = CGFloat((rgb >> 8) & 0xF) / 15.0
            g = CGFloat((rgb >> 4) & 0xF) / 15.0
            b = CGFloat(rgb & 0xF) / 15.0
        case 6: // RRGGBB (24-bit)
            a = alpha ?? 1.0
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            b = CGFloat(rgb & 0xFF) / 255.0
        case 8: // AARRGGBB (32-bit)
            a = alpha ?? CGFloat((rgb >> 24) & 0xFF) / 255.0
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            b = CGFloat(rgb & 0xFF) / 255.0
        default:
            a = alpha ?? 1.0
            r = 0
            g = 0
            b = 0
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    /// 获取颜色的 HEX 字符串表示（格式：#RRGGBB）
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)
        )
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    /// 点击非文本区域隐藏键盘（适用于全屏场景）
    func hideKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.resignFirstResponder()
                }
        )
    }
    
}
