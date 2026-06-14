//
//  SKThemeSetController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/8.
//

import UIKit

class SKThemeSetController: SKBaseController {

    @IBOutlet weak var iconView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        print("userInterfaceStyle 000 = \(userInterfaceStyle)")
        view.backgroundColor = UIColor.dynamicColor(light: .white, dark: .gray)
        
        navBar.backgroundColor = UIColor.dynamicColor(light: .cyan, dark: .yellow)
        
        iconView.image = UIImage(named: "blue_fish")
//        iconView.image = UIImage.dynamicImage(light: UIImage(named: "卡通鲸鱼1"), dark: UIImage(named: "卡通鸟1"))
    }

    @IBAction func changeThemeClick(_ sender: UIButton) {
        // 更新所有窗口的主题
        if ALThemeManager.shared.lastSavedAppTheme == .dark {
            ALThemeManager.shared.setAppTheme(.light)
        } else {
            ALThemeManager.shared.setAppTheme(.dark)
        }
    }
    
}
