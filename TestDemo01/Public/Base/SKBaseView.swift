//
//  SKBaseView.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/6.
//

import UIKit

class SKBaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeUI() {
        
    }
    
    lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    deinit {
        debugPrint("deinit ----- \(type(of: self))")
    }

}
