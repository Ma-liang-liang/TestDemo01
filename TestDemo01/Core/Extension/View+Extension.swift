//
//  View+Extension.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/25.
//

import SwiftUI

extension View {
    /// 获取视图在指定坐标系中的 frame 并监听变化
    func trackFrame(in coordinateSpace: CoordinateSpace = .global,
                   onChange: @escaping (CGRect) -> Void) -> some View {
        self
            .ignoresSafeArea()
            .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        onChange(geometry.frame(in: coordinateSpace))
                    }
                    .onChange(of: geometry.frame(in: coordinateSpace)) { newFrame in
                        onChange(newFrame)
                    }
            }
        )
    }
}
