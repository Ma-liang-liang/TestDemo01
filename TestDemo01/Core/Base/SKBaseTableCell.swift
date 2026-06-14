//
//  SKBaseTableCell.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/6.
//

import UIKit

class SKBaseTableCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeUI() { }
    
    lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
}
