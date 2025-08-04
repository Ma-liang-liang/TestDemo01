//
//  ALDetailItemPage.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/17.
//

import SwiftUI

struct ALDetailItemPage: View {
    
    @Environment(\.dismiss) private var dismiss

    var title = "默认文本"
    
    var body: some View {
        
        ZStack {
            Color.green
            VStack {
                ALNavBarView {
                    dismiss.callAsFunction()
                }
                getHorView()
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .interactiveDismissDisabled(false)

    }
    
    @ViewBuilder
    func getHorView() -> some View {
        HStack {
            Spacer()
                .frame(width: 16)
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.red)
        }
        .frame(maxWidth: .infinity, maxHeight: 60)
        .background(Color.white)
    }
    
}

#Preview {
    ALDetailItemPage()
}
