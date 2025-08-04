//
//  ALLiveViewController.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/19.
//
import UIKit

// MARK: - 使用示例
class ALLiveGiftController: UIViewController {
    private var giftManager: ALGiftRunwayManager!
    
    private var  broadcastManager: ALBroadcastManager!

    // 创建跑马灯标签
    let marqueeLabel = MarqueeLabel(frame: CGRect(x: 20, y: 100, width: 200, height: 40))
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
       
        do {
            
            broadcastManager = ALBroadcastManager(parentView: self.view)
            // 2. 自定义配置（可选）
            var config = ALBroadcastConfig()
            config.maxRunways = 2
            config.centerHoverDuration = 1.0
            config.offsetFromTop = 100
            config.enterAnimationDuration = 2
            config.exitAnimationDuration = 2
            broadcastManager.updateConfig(config)
        }
        
        // 初始化礼物跑道管理器
        var config = ALGiftRunwayConfig()
        config.maxRunways = 3
        config.enterAnimationDuration = 0.5
        config.hoverDuration = 1.0 // 缩短悬停时间以便测试
        config.exitAnimationDuration = 0.5 // 加长退场时间，更容易观察到中断效果
        
        giftManager = ALGiftRunwayManager(parentView: view, config: config)
        setupTestButtons()
        
    

        // 配置基本属性
        marqueeLabel.text = "这是一段需要跑马灯效果的长文本，当文字超出标签宽度时自动滚动"
        marqueeLabel.textColor = .white
        marqueeLabel.backgroundColor = .red
        marqueeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        let marAtt = NSMutableAttributedString {
            "这是一段"
                .cg_mutableAttributedString
                .cg_setFont(16.mediumFont)
                .cg_setColor(.blue)
            "需要跑马灯效果的长文本，当文字超出"
                .cg_mutableAttributedString
                .cg_setFont(13.regularFont)
                .cg_setColor(.white)
            "标签宽度"
                .cg_mutableAttributedString
                .cg_setFont(16.mediumFont)
                .cg_setColor(.green)
            "时自动滚动"
                .cg_mutableAttributedString
                .cg_setFont(13.regularFont)
                .cg_setColor(.white)
            
        }
        
        marqueeLabel.attributedText = marAtt

        // 配置滚动参数
        marqueeLabel.scrollDuration = 2.0   // 滚动一遍耗时
        marqueeLabel.spacing = 30           // 文本间距
        marqueeLabel.direction = .left     // 从右向左滚动
        marqueeLabel.repeatCount = 0        // 滚动2次后停止（设为0表示无限循环）

        // 添加到视图
        view.addSubview(marqueeLabel)
        
        marqueeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(60)
            make.top.equalToSuperview().offset(200)
        }

        // 手动控制动画
//        marqueeLabel.startAnimation()      // 开始动画
//        marqueeLabel.pauseAnimation()       // 暂停动画
//        marqueeLabel.resumeAnimation()      // 继续动画
//        marqueeLabel.stopAnimation()        // 停止动画

        // 手动控制动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            self.marqueeLabel.startAnimation() // 开始动画
        }
//        marqueeLabel.stopAnimation()  // 停止动画
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        giftManager.clearAllRunways()
        broadcastManager.clearAllBroadcasts()
    }
    
    
    private func setupTestButtons() {
        let button1 = UIButton(type: .system)
        button1.setTitle("送玫瑰 (用户12)", for: .normal)
        button1.backgroundColor = .systemBlue
        button1.setTitleColor(.white, for: .normal)
        button1.layer.cornerRadius = 8
        button1.addTarget(self, action: #selector(sendRose), for: .touchUpInside)
        
        let button2 = UIButton(type: .system)
        button2.setTitle("送跑车 (随机土豪)", for: .normal)
        button2.backgroundColor = .systemRed
        button2.setTitleColor(.white, for: .normal)
        button2.layer.cornerRadius = 8
        button2.addTarget(self, action: #selector(sendCar), for: .touchUpInside)
        
        let button3 = UIButton(type: .system)
        button3.setTitle("清空", for: .normal)
        button3.backgroundColor = .systemGray
        button3.setTitleColor(.white, for: .normal)
        button3.layer.cornerRadius = 8
        button3.addTarget(self, action: #selector(clearGifts), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [button1, button2, button3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let button4 = UIButton(type: .system)
        button4.setTitle("发送广播", for: .normal)
        button4.backgroundColor = .systemGray
        button4.setTitleColor(.white, for: .normal)
        button4.layer.cornerRadius = 8
        button4.addTarget(self, action: #selector(sendBroadcast), for: .touchUpInside)
        button4.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviews {
            button4
        }

        button4.snp.makeConstraints { make in
            make.bottom.equalTo(stackView.snp.top).offset(-12)
            make.leading.equalToSuperview().inset(20)
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        
    }
    
    @objc private func sendBroadcast() {
        // 3. 显示广播
//        let broadcast1 = ALBroadcastItem(
//            title: "系统通知",
//            message: "您有新的消息，请及时查看",
//            backgroundColor: .systemRed
//        )
//        broadcastManager.showBroadcast(broadcast1)
        
        let broadcast2 = ALBroadcastItem(
            title: "活动提醒",
            message: "限时活动即将开始，快来参与吧！",
            icon: "activity_icon",
            backgroundColor: .random
        )
        broadcastManager.showBroadcast(broadcast2)
        
//        // 4. 清理所有广播（可选）
//        broadcastManager.clearAllBroadcasts()
    }
    
    @objc private func sendRose() {
        //        let gift = GiftItem(
        //            userName: "用户\(Int.random(in: 1...100))",
        //            userAvatar: "",
        //            giftName: "玫瑰花",
        //            giftIcon: "",
        //            comboCount: Int.random(in: 1...5)
        //        )
        //        giftManager.addGift(gift)
        let gift = ALGiftItem(
            userName: "用户 12",
            userAvatar: "",
            giftName: "玫瑰花",
            giftIcon: "",
            comboCount: Int.random(in: 1...5)
        )
        giftManager.addGift(gift)
    }
    
    @objc private func sendCar() {
        let gift = ALGiftItem(
            userName: "土豪\(Int.random(in: 1...50))",
            userAvatar: "",
            giftName: "跑车",
            giftIcon: "",
            comboCount: Int.random(in: 1...3)
        )
        giftManager.addGift(gift)
    }
    
    @objc private func clearGifts() {
        giftManager.clearAllRunways()
    }
}
