//
//  HomeController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/26.
//

import UIKit
import SnapKit
import SwifterSwift
import SwiftUI

class HomeController: SKBaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubviews {
            jumpBtn
            jumpBtn1
            jumpBtn2
        }
        
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
        jumpBtn1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(100)
            make.top.equalTo(jumpBtn.snp.bottom).offset(40)
            make.height.equalTo(36)
        }
        
        jumpBtn2.snp.makeConstraints { make in
            make.top.equalTo(jumpBtn1.snp.bottom).offset(40)
            make.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }
        
    }
    
    @objc
    func onJumpClick(_ sender: UIButton) {
        if sender == jumpBtn {
            let vc = UIHostingController(rootView: MainTabBarControllerRepresentable())
            //            vc.modalPresentationStyle = .overFullScreen
            //            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        } else if sender == jumpBtn1 {
            let page = ALSheetPage(onDismiss: {
                
            }, onPinkAreaTap: {
                
            })
            let vc = UIHostingController(rootView: page)
            vc.view.backgroundColor = .clear
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        } else if sender == jumpBtn2 {
            let vc = ALCollectionController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    lazy var jumpBtn: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
    lazy var jumpBtn1: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转1  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
    lazy var jumpBtn2: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转2  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
}
