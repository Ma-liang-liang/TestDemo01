//
//  ALRechargeViewModel.swift
//  TestDemo
//
//  Created by maliangliang on 2025/6/25.
//

import SwiftUI


// MARK: - 单个支付选项模型
class ALPaymentOptionModel: Identifiable, ObservableObject {
    let id = UUID()
    var amount = ""
    var coins = ""
    @Published var isSelected = false
    
    init(amount: String = "", coins: String = "", isSelected: Bool = false) {
        self.amount = amount
        self.coins = coins
        self.isSelected = isSelected
    }
}

class ALTopUpViewModel: ObservableObject {
    
    @Published var optionModels: [ALPaymentOptionModel] = []
    
    @Published var selectedOption: ALPaymentOptionModel? {
        didSet {
            // 更新所有选项的选中状态
            optionModels.forEach { $0.isSelected = ($0.id == selectedOption?.id) }
        }
    }
    
    init() {
        self.optionModels = [
            ALPaymentOptionModel(amount: "$100", coins: "1000"),
            ALPaymentOptionModel(amount: "$100", coins: "1000"),
            ALPaymentOptionModel(amount: "$100", coins: "1000"),
            ALPaymentOptionModel(amount: "$100", coins: "1000"),
            ALPaymentOptionModel(amount: "$100", coins: "1000"),
            ALPaymentOptionModel(amount: "$100", coins: "1000")
        ]
    }
}
