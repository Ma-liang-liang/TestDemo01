//
//  SKBaseController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/27.
//

import UIKit
import Combine
import SwifterSwift

class SKBaseController: UIViewController {

    var cancelables = Set<AnyCancellable>()
    
    var needNavBar: Bool { true }
    
    lazy var navBar: SKNavigationBar = {
        let view = SKNavigationBar()
        view.backBtn.addTarget(self, action: #selector(onClickNavBarBackButton), for: .touchUpInside)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .random.lighten(by: 0.1)
        navigationController?.setNavigationBarHidden(true, animated: false)
        if needNavBar {
            view.addSubviews {
                navBar
            }
            navBar.snp.makeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
    
    func makeUI() {
        
    }
    
    @objc func onClickNavBarBackButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    func addNotification(name: String) {
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveNotification), name: Notification.Name(name), object: nil)
    }
    
    @objc func onReceiveNotification(noti: Notification) {
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("deinit ===== \(type(of: self))")
    }

}
