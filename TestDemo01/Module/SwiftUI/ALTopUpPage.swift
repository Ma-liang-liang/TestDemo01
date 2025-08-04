//
//  TestSwiftUIView.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/25.
//

import SwiftUI

// MARK: - 主视图
struct ALTopUpPage: View {
    
    @StateObject private var viewModel = ALTopUpViewModel()
    
    @State private var isChecked = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部导航栏
            TopNavigationBar()
            
            // 余额显示区域
            BalanceView(balance: 9999)
            
            // 支付选项区域
            PaymentOptionsView(viewModel: viewModel)
            
           
            ALCheckAgreementView(isChecked: $isChecked,
                                 agreementText: "View 《KK Currency Recharge Agreement》") {
                
            }
            
            // 底部支付按钮
            rechargeButton
        }
        .padding(0)
        .background(Color.white) // 白色背景
        .navigationBarBackButtonHidden(true) // 隐藏默认返回按钮
        //        .preferredColorScheme(.dark)
    }
    
    private var rechargeButton: some View {
        
        ZStack {
            // 水平渐变（从左到右）
           LinearGradient(
               colors: [Color(hex: "#FFE48E"), Color(hex: "#FFB7A1")],
               startPoint: .leading,
               endPoint: .trailing
           )
            Button(action: {
                // 处理支付逻辑
            }) {
                Text("Immediate recharge")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 44)
        .cornerRadius(22)
        .padding(.horizontal, 70)
    }
    
}
extension ALTopUpPage {
    
    // MARK: - 顶部导航栏组件
    struct TopNavigationBar: View {
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            HStack(spacing: 0) {
                // 返回箭头按钮
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44) // 增加点击区域
                }
                
                // 标题
                Text("K coin")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(height: 50) // 固定导航栏高度
        }
    }
    
}

extension ALTopUpPage {
    // MARK: - 余额区域组件
    struct BalanceView: View {
        let balance: Int
        
        var body: some View {
           
            ZStack {
                // 水平渐变（从左到右）
               LinearGradient(
                   colors: [Color(hex: "#FFE48E"), Color(hex: "#FFB7A1")],
                   startPoint: .leading,
                   endPoint: .trailing
               )
                
                cardContent
            }
            .frame(height: 108)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .clipped()

        }
        
        private var cardContent: some View {
            
            HStack() {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    // 当前余额文字
                    Text("Current balance")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.55))
                    
                    // 余额数字
                    Text("\(balance)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.85))
                    
                    Spacer()
                }
                .padding(.leading, 24)
                
                Spacer()
                // 交易记录按钮
                VStack {
                    Spacer()
                        .frame(height: 24)
                    Button {
                        // 交易记录操作
                        
                    } label: {
                        
                        Text("Transaction record")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.black.opacity(0.55))
                            .padding(.leading, 12)
                            .padding(.trailing, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.60))
                            .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                    }
                    
                    Spacer()
                }
            }
//            .background(alignment: .center, content: {
//                // 橙色背景
//                Color.orange
//                    .opacity(0.6)
//            })
        }
    }
}

extension ALTopUpPage {
    
    // MARK: - 支付选项网格
    struct PaymentOptionsView: View {
        
        @ObservedObject var viewModel: ALTopUpViewModel
        
        let options = Array(repeating: ALPaymentOptionModel(amount: "$100", coins: "1000"), count: 6)
        
        // 定义网格列（每行3列）
        private var columns: [GridItem] {
            Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                // 支付标题
                Text("Apple支付")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 12)
                
                // 网格布局
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(viewModel.optionModels.indices, id: \.self) { index in
                        let model = viewModel.optionModels[index]
                        PaymentOptionView(option: model,
                                          actionBlock: {
                            
                            viewModel.selectedOption = model
                            
                        })
                        
                    }
                }
                .padding(12)
                .background(alignment: .center) {
                    Color.black.opacity(0.05)
                        .cornerRadius(16)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
}

extension ALTopUpPage {
    
    // MARK: - 支付选项按钮
    struct PaymentOptionView: View {
        let option: ALPaymentOptionModel
        let actionBlock: (() -> Void)?
        
        var body: some View {
            Button(action: {
                actionBlock?()
            }) {
                VStack(spacing: 6) {
                    Text(option.amount)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.6))
                    
                    HStack(spacing: 2) {
                        Image("recharge_diamond")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text(option.coins)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(uiColor: .themeColor))
                    }
                }
                .foregroundColor(option.isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 108)
                .cornerRadius(16)
                .background(option.isSelected ? Color(hex: "#F5B75B", alpha: 0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(option.isSelected ? Color(uiColor: .themeColor) : Color.cyan, lineWidth: 2)
                )
            }
        }
    }
    
}

struct ALCheckAgreementView: View {
    
    @Binding var isChecked: Bool
    
    let agreementText: String
    
    let onAgreementTapped: () -> Void
  
    var body: some View {
        
        HStack(spacing: 8) {
            // 单选按钮（自定义样式）
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isChecked.toggle()
                }
            }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isChecked ? Color(uiColor: .themeColor) : .black.opacity(0.12))
                    .transition(.scale)
            }
            
            // 协议文本（可点击）
            Button(action: onAgreementTapped) {
                Text(agreementText)
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.55))
                    .underline()
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // 扩大点击区域
    }
}

// MARK: - 预览
struct KCoinView_Previews: PreviewProvider {
    static var previews: some View {
        ALTopUpPage()
    }
}

