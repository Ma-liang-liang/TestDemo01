//
//  SecondViewModel.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/11.
//

import Combine
import SwiftUI

class ThirdViewModel: ObservableObject {
  
    @Published var items: [String] = []
    
    @Published var navPath = NavigationPath()
    
    func test() async {
        
        await MainActor.run {
            getInfo()
        }
    }
    
    @MainActor
    func getInfo() {
        
    }

}
// 1. 定义可编码的路由类型
enum AppRoute: Codable, Hashable {
    case home
    case profile
    case settings
    case detail(id: String)
    // 添加更多路由...
}

