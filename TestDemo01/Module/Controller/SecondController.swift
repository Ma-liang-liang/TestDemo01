//
//  SecondController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/27.
//

import UIKit
import SnapKit
import SwifterSwift
import Combine

class SecondController: SKBaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()


        view.addSubview(jumpBtn)
        
        jumpBtn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(100)
            make.height.equalTo(36)
        }

        yellowView.backgroundColor = .yellow
        view.addSubviews {
            yellowView
            leftBtn
            rightBtn
        }
        
        yellowView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(200)
            make.centerY.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(60)
        }
        
        leftBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.top.equalTo(jumpBtn.snp.bottom).offset(40)
        }
        
        rightBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(jumpBtn.snp.bottom).offset(40)
        }
        
        animator = ReversibleAnimator(targetView: yellowView, duration: 2)

    }
    
    
    @objc
    func onJumpClick(_ sender:UIButton) {
//        let vc = SecondController()
//        navigationController?.pushViewController(vc)
        
        if sender == leftBtn {
            animator?.startForwardAnimation()
        } else if sender == rightBtn {
            animator?.startReverseAnimation()
        }
    }
    
    var animator: ReversibleAnimator?

    lazy var jumpBtn: UIButton = {
        let button = UIButton()
        button.setTitle("  跳转  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
    lazy var leftBtn: UIButton = {
        let button = UIButton()
        button.setTitle(" left  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
    lazy var rightBtn: UIButton = {
        let button = UIButton()
        button.setTitle(" right  ", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.addTarget(self, action: #selector(onJumpClick), for: .touchUpInside)
        return button
    }()
    
    let yellowView = UIView()


}
class ReversibleAnimator {
    private var animator: UIViewPropertyAnimator?
    private var isAnimatingForward = true
    private weak var targetView: UIView?
    private let animationDuration: TimeInterval
    
    init(targetView: UIView, duration: TimeInterval = 0.5) {
        self.targetView = targetView
        self.animationDuration = duration
    }
    
    // 开始正向动画（移出屏幕）
    func startForwardAnimation() {
        guard let view = targetView else { return }
        
        // 停止现有动画
        animator?.stopAnimation(false)
        
        let parentWidth = view.superview?.bounds.width ?? UIScreen.main.bounds.width
        let endTransform = CGAffineTransform(translationX: -parentWidth, y: 0)
        
        animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeIn) {
            view.transform = endTransform
            view.alpha = 0.0
        }
        
        animator?.addCompletion { [weak self] position in
            guard let self = self else { return }
            if position == .end && self.isAnimatingForward {
//                view.removeFromSuperview()
            }
        }
        
        isAnimatingForward = true
        animator?.startAnimation()
    }
    
    // 停止并反向动画（返回原位）
    func startReverseAnimation() {
        guard let view = targetView else { return }
        
        // 停止当前动画（保留当前状态）
        animator?.stopAnimation(false)
        animator?.finishAnimation(at: .current)
        // 计算剩余时间比例
        let remainingProgress = 1.0 - (animator?.fractionComplete ?? 0)
        let reverseDuration = animationDuration * remainingProgress
        
        animator = UIViewPropertyAnimator(duration: reverseDuration, curve: .easeOut) {
            view.transform = .identity
            view.alpha = 1.0
        }
        
        animator?.addCompletion { [weak self] _ in
            self?.isAnimatingForward = false
        }
        
        isAnimatingForward = false
        animator?.startAnimation()
    }
    
    // 立即停止动画（可选择是否保留状态）
    func stopAnimation(shouldReset: Bool = false) {
        animator?.stopAnimation(shouldReset)
        if shouldReset {
            targetView?.transform = .identity
            targetView?.alpha = 1.0
        }
    }
    
    // 清理资源
    deinit {
        animator?.stopAnimation(true)
    }
}
