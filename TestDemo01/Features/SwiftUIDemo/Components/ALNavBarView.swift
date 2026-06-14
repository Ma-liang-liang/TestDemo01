//
//  ALNavBarView.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/17.
//

import SwiftUI

struct ALNavBarView: View {
    
    let backCallBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: UIScreen.statusBarHeight)
            HStack {
                Spacer()
                    .frame(width: 16)
                Image(systemName: "xmark")
                    .resizable()
                    .foregroundStyle(Color.black)
                    .frame(width: 20, height: 20)
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture {
                        backCallBack?()
                    }
                Spacer()
            }
            .frame(width: UIScreen.kScreenWidth,height: 44)
            .background(Color.yellow)
        }
        .frame(height: UIScreen.kNavBarHeight)
    }
}

#Preview {
    ALNavBarView(backCallBack: nil)
}
