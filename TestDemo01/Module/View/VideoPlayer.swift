//
//  VideoPlayer.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/24.
//
import UIKit
import AVFoundation

class VideoPlayer: UIView {
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var isFullscreen = false
    private var originalFrame: CGRect = .zero
    
    var videoURL: URL? {
        didSet { setupPlayer() }
    }
    
    var qualities: [VideoQuality] = [] {
        didSet { controlView.isHidden = qualities.isEmpty }
    }
    
    // MARK: - UI Components
    private lazy var controlView: VideoPlayerControlView = {
        let view = VideoPlayerControlView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap11(_:)))
        gesture.numberOfTapsRequired = 1
        return gesture
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .black
        clipsToBounds = true
        addSubview(controlView)
        addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor),
            controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func setupPlayer() {
        guard let url = videoURL else { return }
        
        // Clean up previous player
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        removeObservers()
        
        // Initialize new player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = bounds
        layer.insertSublayer(playerLayer!, at: 0)
        
        addObservers()
        play()
    }
    
    // MARK: - Gesture Handling
    @objc private func handleTap11(_ gesture: UITapGestureRecognizer) {
        let targetAlpha: CGFloat = controlView.alpha == 0 ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            self.controlView.alpha = targetAlpha
        }
        
        // Auto-hide after 3 seconds if showing
        if targetAlpha == 1 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
            perform(#selector(hideControls), with: nil, afterDelay: 3.0)
        }
    }
    
    @objc private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlView.alpha = 0
        }
    }
    
    // MARK: - Player Observers
    private func addObservers() {
        addTimeObserver()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self, !self.controlView.isSliding else { return }
            
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self.playerItem?.duration ?? .zero)
            
            if !duration.isNaN {
                self.controlView.updateTime(currentTime: currentTime, duration: duration)
            }
            
            self.updateBufferedTime()
        }
    }
    
    private func updateBufferedTime() {
        guard let loadedRange = playerItem?.loadedTimeRanges.first?.timeRangeValue else { return }
        let bufferedTime = CMTimeGetSeconds(loadedRange.start) + CMTimeGetSeconds(loadedRange.duration)
        controlView.updateBufferedTime(bufferedTime: bufferedTime)
    }
    
    private func removeObservers() {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func removeTimeObserver() {
        guard let observer = timeObserver else { return }
        player?.removeTimeObserver(observer)
        timeObserver = nil
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    // MARK: - Notification Handlers
    @objc private func playerItemDidPlayToEndTime() {
        seek(to: 0)
        controlView.updatePlaybackStatus(isPlaying: false)
    }
    
    @objc private func applicationWillResignActive() {
        pause()
    }
    
    @objc private func applicationDidBecomeActive() {
        if controlView.isPlaying {
            play()
        }
    }
    
    // MARK: - Public Controls
    func play() {
        player?.play()
        controlView.updatePlaybackStatus(isPlaying: true)
    }
    
    func pause() {
        player?.pause()
        controlView.updatePlaybackStatus(isPlaying: false)
    }
    
    func toggleFullscreen() {
        guard let _ = superview else { return }
        
        if isFullscreen {
            exitFullscreen()
        } else {
            enterFullscreen()
        }
        
        isFullscreen.toggle()
        controlView.updateFullscreenStatus(isFullscreen: isFullscreen)
        showControlsTemporarily()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func forward(seconds: TimeInterval = 10) {
        guard let currentTime = player?.currentTime() else { return }
        let duration = CMTimeGetSeconds(playerItem?.duration ?? .zero)
        let newTime = min(CMTimeGetSeconds(currentTime) + seconds, duration)
        seek(to: newTime)
    }
    
    func backward(seconds: TimeInterval = 10) {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = max(CMTimeGetSeconds(currentTime) - seconds, 0)
        seek(to: newTime)
    }
    
    func changeQuality(to quality: VideoQuality) {
        videoURL = quality.url
    }
    
    // MARK: - Private Helpers
    private func enterFullscreen() {
        guard let superview = superview else { return }
        originalFrame = frame
        
        UIView.animate(withDuration: 0.3) {
            self.transform = CGAffineTransform(rotationAngle: .pi/2)
            self.frame = superview.bounds
        }
    }
    
    private func exitFullscreen() {
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
            self.frame = self.originalFrame
        }
    }
    
    private func showControlsTemporarily() {
        UIView.animate(withDuration: 0.3) {
            self.controlView.alpha = 1
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
        perform(#selector(hideControls), with: nil, afterDelay: 3.0)
    }
}

// MARK: - VideoPlayerControlViewDelegate
extension VideoPlayer: VideoPlayerControlViewDelegate {
    func controlViewDidTapPlayPause(_ controlView: VideoPlayerControlView) {
        controlView.isPlaying ? pause() : play()
    }
    
    func controlViewDidTapFullscreen(_ controlView: VideoPlayerControlView) {
        toggleFullscreen()
    }
    
    func controlView(_ controlView: VideoPlayerControlView, didSelectQuality quality: VideoQuality) {
        changeQuality(to: quality)
    }
    
    func controlView(_ controlView: VideoPlayerControlView, isSeekingTo time: TimeInterval) {
        seek(to: time)
    }
    
    func controlView(_ controlView: VideoPlayerControlView, didSeekTo time: TimeInterval) {
        seek(to: time)
    }
    
    func controlViewDidTapBackward(_ controlView: VideoPlayerControlView) {
        backward()
    }
    
    func controlViewDidTapForward(_ controlView: VideoPlayerControlView) {
        forward()
    }
}
