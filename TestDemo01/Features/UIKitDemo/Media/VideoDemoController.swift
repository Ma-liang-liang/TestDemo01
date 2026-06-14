//
//  VideoDemoController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/24.
//

import UIKit

class VideoDemoController: SKBaseController {
    
    private var videoPlayer: VideoPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup video player
        videoPlayer = VideoPlayer()
        view.addSubview(videoPlayer)
        
        // Layout constraints
        videoPlayer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoPlayer.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 20),
            videoPlayer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            videoPlayer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            videoPlayer.heightAnchor.constraint(equalTo: videoPlayer.widthAnchor, multiplier: 9/16)
        ])
        
        // Setup video URL and qualities
        let videoURL1 = URL(string: "https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4")!
        let videoURL2 = URL(string: "https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/peter/mac-peter-tpl-cc-us-2018_1280x720h.mp4")!
        
        let videoURL3 = URL(string: "https://cdn.cnbj1.fds.api.mi-img.com/mi-mall/7194236f31b2e1e3da0fe06cfed4ba2b.mp4")!
        
        let videoURL4 = URL(string: "https://cdn.cnbj1.fds.api.mi-img.com/mi-mall/7194236f31b2e1e3da0fe06cfed4ba2b.mp4")!
        
        videoPlayer.videoURL = videoURL3
        
        let qualities:[VideoQuality] = [
            VideoQuality(title: "720p", url: videoURL1)
        ]
        
        videoPlayer.qualities = qualities
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayer.pause()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
}
