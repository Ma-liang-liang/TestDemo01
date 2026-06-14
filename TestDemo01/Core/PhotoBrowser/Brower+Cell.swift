//
//  Brower+Cell.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/15.
//

import Foundation
import UIKit
import SnapKit
import Kingfisher
import AVKit


extension MediaBrowserViewController {
    
    // MARK: - 图片Cell
    class ImageCell: UICollectionViewCell, UIScrollViewDelegate {
        private var resource: MediaResource?
        weak var delegate: MediaBrowserDelegate?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI() {
         
            contentView.addSubviews {
                scrollView
            }
            
            scrollView.addSubviews {
                imageView
            }
            scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.width.equalToSuperview()
            }
                        
            imageView.contentMode = .top
            imageView.clipsToBounds = true
            
            imageView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.greaterThanOrEqualTo(360)
                make.width.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
                make.centerY.equalToSuperview()
            }
            
            imageView.backgroundColor = .white
            scrollView.setContentOffset(.zero, animated: false)
        }
        
        private func setupGestures() {
            //        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            //        doubleTap.numberOfTapsRequired = 2
            //        addGestureRecognizer(doubleTap)
            //
            //        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            //        addGestureRecognizer(longPress)
        }
        
        func configure(with resource: MediaResource) {
            self.resource = resource
            guard let url = URL(string: resource.url) else {
                return
            }
            
//            imageView.kf.setImage(
//                with: url,
//                placeholder: resource.placeholder,
//                options: resource.type == .gif ? [.processor(DefaultImageProcessor.default)] : nil) { [weak self] res in
//                    switch res {
//                    case let .success(imageRes):
//                        DispatchQueue.main.async {
//                            self?.updateImageLayout(imageResult: imageRes)
//                        }
//                    case let .failure(error):
//                        break
//                    }
//                }
                   
        }
        
        private func updateImageLayout(imageResult :RetrieveImageResult) {
          
            guard let targetImage = imageResult.image.resized(toWidth: UIScreen.kScreenWidth) else {
                return
            }

            if targetImage.size.height < UIScreen.kScreenHeight {
                scrollView.isScrollEnabled = false
            } else {
                scrollView.isScrollEnabled = true
            }
        }
        
        @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            let zoomScale = scrollView.zoomScale == 1.0 ? 2.0 : 1.0
            scrollView.setZoomScale(zoomScale, animated: true)
            delegate?.didDoubleTapMedia(at: tag)
        }
        
        @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            delegate?.didLongPressMedia(at: tag)
        }
        
        lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
                .cg_showsVerticalScrollIndicator(false)
            
            return view
        }()
        
        lazy var imageView: UIImageView = {
            let view = UIImageView()
            return view
        }()
        
        // MARK: - UIScrollViewDelegate
    }
    
}


extension MediaBrowserViewController {
    
    // MARK: - 视频Cell
    class VideoCell: UICollectionViewCell {
        private let playerView = UIView()
        private var player: AVPlayer?
        private var playerLayer: AVPlayerLayer?
        private let controlBar = VideoControlBar()
        private var resource: MediaResource?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI() {
            playerView.backgroundColor = .black
            contentView.addSubview(playerView)
            playerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            contentView.addSubview(controlBar)
            controlBar.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(60)
            }
            controlBar.playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        }
        
        func configure(with resource: MediaResource) {
            self.resource = resource
            
            // 显示视频缩略图
            if let thumbnail = resource.thumbnail {
                let imageView = UIImageView(image: thumbnail)
                imageView.contentMode = .scaleAspectFit
                playerView.addSubview(imageView)
                imageView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            
            // 初始化播放器
            guard let url = URL(string: resource.url) else {
                return
            }
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspect
            playerView.layer.addSublayer(playerLayer!)
            
            // 添加进度观察
            player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main) { [weak self] time in
                guard let duration = self?.player?.currentItem?.duration else { return }
                let progress = Float(time.seconds / duration.seconds)
                self?.controlBar.progressView.progress = progress
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = playerView.bounds
        }
        
        @objc private func togglePlay() {
            guard let player = player else { return }
            if player.rate == 0 {
                player.play()
                controlBar.playButton.setImage(UIImage(named: "pause_icon"), for: .normal)
            } else {
                player.pause()
                controlBar.playButton.setImage(UIImage(named: "play_icon"), for: .normal)
            }
        }
    }

    
}

