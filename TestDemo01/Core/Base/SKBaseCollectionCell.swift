//
//  SKBaseCollectionCell.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/6.
//

import UIKit

class SKBaseCollectionCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeUI() { }
    
}
