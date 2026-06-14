//
//  SKNavigationBar.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/14.
//

import UIKit
import SnapKit

class SKNavigationBar: SKBaseView {
    
    lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        let image = SystemIcon.getIcon(icon: .arrowLeft)
//        let image = AppIcon.close.image()
        btn.setImage(image, for: .normal)
        return btn
    }()
    
    lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .black
        lb.font = 16.mediumFont
        lb.textAlignment = .center
        return lb
    }()
    
    lazy var shadowLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.gray_9E9E9E_color
        line.isHidden = true
        return line
    }()
    
    lazy var rightBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.isHidden = true
        return btn
    }()
    
    override func makeUI() {
        backgroundColor = .white
        container.backgroundColor = .clear
        isUserInteractionEnabled = true
        addSubviews {
            container
            shadowLine
        }
        
        container.addSubviews {
            backBtn
            titleLabel
            rightBtn
        }
        
        container.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(UIScreen.safeAreaTopHeight)
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        
        backBtn.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(60)
            make.top.bottom.equalToSuperview()
        }
        
        rightBtn.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        shadowLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
     
    }
    
    
}
