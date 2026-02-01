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
import YYImage
import YYText

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
        
        // 加载并显示动图
        setupAnimatedImageView()
        
        // 设置 YYLabel 显示富文本
        setupRichTextLabel()

    }
    
    func setupAnimatedImageView() {
        // 方法1: 尝试使用 imageNamed 方法（推荐方式）
        if let image = YYImage(named: "001.webp" ) {
            print("✅ 使用 imageNamed 成功加载图片")
            setupImageView(with: image)
            return
        }
        
        // 方法2: 尝试使用完整路径加载
        if let imagePath = Bundle.main.path(forResource: "001", ofType: "webp") {
            print("📁 找到文件路径: \(imagePath)")
            
            // 检查文件是否存在
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: imagePath) {
                print("✅ 文件存在")
                
                // 尝试使用 imageWithContentsOfFile 类方法
                if let image = YYImage(contentsOfFile: imagePath) {
                    print("✅ 使用 imageWithContentsOfFile 成功加载图片")
                    setupImageView(with: image)
                    return
                }
               
            } else {
                print("❌ 文件不存在于路径: \(imagePath)")
            }
        } else {
            print("❌ 无法找到 001.webp 文件路径")
            // 打印所有 bundle 中的资源文件（用于调试）
            if let resourcePath = Bundle.main.resourcePath {
                print("📦 Bundle 资源路径: \(resourcePath)")
            }
        }
        
        print("❌ 所有加载方式都失败，无法显示图片")
    }
    
    func setupImageView(with image: YYImage) {
        // 创建 YYAnimatedImageView 来显示动图
        animatedImageView.image = image
        animatedImageView.contentMode = .scaleAspectFit
        
        view.addSubview(animatedImageView)
        
        animatedImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(rightBtn.snp.bottom).offset(40)
            make.width.equalTo(200)
            make.height.equalTo(200)
        }
        
        print("✅ 图片视图已添加到界面")
    }
    
    func setupRichTextLabel() {
        // 创建富文本
        let attributedText = NSMutableAttributedString()
        
        // 设置字体
        let font = UIFont.systemFont(ofSize: 16)
        let textColor = UIColor.label
        
        // 1. 添加文本
        let text1 = NSAttributedString(string: "这是一段包含", attributes: [
            .font: font,
            .foregroundColor: textColor
        ])
        attributedText.append(text1)
        
        // 2. 添加静态图片
        if let staticImage = UIImage(systemName: "star.fill") {
            // 计算图片宽度，保持宽高比，高度为19
            let imageHeight: CGFloat = 19
            let imageWidth = staticImage.size.width / staticImage.size.height * imageHeight
            
            let imageAttachment = NSMutableAttributedString.yy_attachmentString(
                withContent: staticImage,
                contentMode: .scaleAspectFit,
                attachmentSize: CGSize(width: imageWidth, height: imageHeight),
                alignTo: font,
                alignment: YYTextVerticalAlignment.center
            )
            attributedText.append(imageAttachment)

//            let attachment = imageAttachment
//            attributedText.append(attachment)
        }
        
        // 3. 继续添加文本
        let text2 = NSAttributedString(string: "静态图片和", attributes: [
            .font: font,
            .foregroundColor: textColor
        ])
        attributedText.append(text2)
        
        // 4. 添加动图
        // 先尝试使用 imageNamed 方法
        var animatedImage: YYImage? = YYImage(named: "001.webp")
        
        // 如果失败，尝试使用文件路径
        if animatedImage == nil {
            if let imagePath = Bundle.main.path(forResource: "001", ofType: "webp") {
                animatedImage = YYImage(contentsOfFile: imagePath)
            }
        }
        
        if let animatedImage = animatedImage {
            // 计算动图宽度，保持宽高比，高度为19
            let imageHeight: CGFloat = 19
            let imageWidth = animatedImage.size.width / animatedImage.size.height * imageHeight
            
            // 创建 YYAnimatedImageView 来显示动图
            let animatedImageView = YYAnimatedImageView()
            animatedImageView.frame = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
            animatedImageView.image = animatedImage
            animatedImageView.contentMode = .scaleAspectFit
            // 确保动图自动播放
            animatedImageView.autoPlayAnimatedImage = true
            
            // 使用正确的方法名添加附件
            let imageAttachment = NSMutableAttributedString.yy_attachmentString(
               withContent: animatedImageView,
               contentMode: .scaleAspectFit,
               attachmentSize: CGSize(width: imageWidth, height: imageHeight),
               alignTo: font,
               alignment: YYTextVerticalAlignment.center
           )
            attributedText.append(imageAttachment)

        }
        let greenV = UIView()
        greenV.backgroundColor = .green
        greenV.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

        // 使用正确的方法名添加附件
        let imageAttachment = NSMutableAttributedString.yy_attachmentString(
           withContent: greenV,
           contentMode: .scaleAspectFit,
           attachmentSize: CGSize(width: 20, height: 20),
           alignTo: font,
           alignment: YYTextVerticalAlignment.center
       )
        attributedText.append(imageAttachment)
        
        // 5. 继续添加文本，包含换行
        let text3 = NSAttributedString(string: "动图的富文本内容。\n这是第二行文本，用来测试换行功能。\n", attributes: [
            .font: font,
            .foregroundColor: textColor
        ])
        attributedText.append(text3)
        
        // 6. 再添加一个静态图片
        if let staticImage2 = UIImage(systemName: "heart.fill") {
            let imageHeight: CGFloat = 19
            let imageWidth = staticImage2.size.width / staticImage2.size.height * imageHeight
            let imageAttachment = NSMutableAttributedString.yy_attachmentString(
                withContent: staticImage2,
                contentMode: .scaleAspectFit,
                attachmentSize: CGSize(width: imageWidth, height: imageHeight),
                alignTo: font,
                alignment: YYTextVerticalAlignment.center
            )
            attributedText.append(imageAttachment)

        }
        
        // 7. 最后添加文本
        let text4 = NSAttributedString(string: "这是第三行，包含更多内容来测试换行和图片混排效果。", attributes: [
            .font: font,
            .foregroundColor: textColor
        ])
        attributedText.append(text4)
        
        // 设置段落样式，支持换行
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byWordWrapping
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        // 配置 YYLabel
        richTextLabel.attributedText = attributedText
        richTextLabel.numberOfLines = 0 // 支持多行
        richTextLabel.textAlignment = .left
        
        // 添加到视图并设置约束
        view.addSubview(richTextLabel)
        richTextLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(animatedImageView.snp.bottom).offset(40)
        }
    }
    
    
    @objc
    func onJumpClick(_ sender:UIButton) {
        if sender == jumpBtn {
            // 跳转到 NTFlexTagsController
            let vc = NTFlexTagsController()
            navigationController?.pushViewController(vc)
        } else if sender == leftBtn {
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
    
    // YYAnimatedImageView 用于显示动图
    lazy var animatedImageView: YYAnimatedImageView = {
        let imageView = YYAnimatedImageView()
        return imageView
    }()
    
    // YYLabel 用于显示富文本
    lazy var richTextLabel: YYLabel = {
        let label = YYLabel()
        label.backgroundColor = UIColor.systemBackground
        return label
    }()


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
