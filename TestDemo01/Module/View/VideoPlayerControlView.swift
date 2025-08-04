//
//  VideoPlayerControlView.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/24.
//
import UIKit
import AVFoundation

protocol VideoPlayerControlViewDelegate: AnyObject {
    func controlViewDidTapPlayPause(_ controlView: VideoPlayerControlView)
    func controlViewDidTapFullscreen(_ controlView: VideoPlayerControlView)
    func controlView(_ controlView: VideoPlayerControlView, didSelectQuality quality: VideoQuality)
    func controlView(_ controlView: VideoPlayerControlView, isSeekingTo time: TimeInterval)
    func controlView(_ controlView: VideoPlayerControlView, didSeekTo time: TimeInterval)
    func controlViewDidTapBackward(_ controlView: VideoPlayerControlView)
    func controlViewDidTapForward(_ controlView: VideoPlayerControlView)
}

struct VideoQuality {
    let title: String
    let url: URL
}

class VideoPlayerControlView: UIView {
    
    // MARK: - Properties
    weak var delegate: VideoPlayerControlViewDelegate?
    
    var isPlaying: Bool = false {
        didSet {
            playPauseButton.setImage(isPlaying ? pauseImage : playImage, for: .normal)
        }
    }
    
    var isSliding = false
    
    private var isFullscreen: Bool = false {
        didSet {
            fullscreenButton.setImage(isFullscreen ? exitFullscreenImage : fullscreenImage, for: .normal)
        }
    }
    
    private var currentTime: TimeInterval = 0 {
        didSet { updateTimeLabels() }
    }
    
    private var duration: TimeInterval = 0 {
        didSet { updateTimeLabels() }
    }
    
    private var bufferedTime: TimeInterval = 0 {
        didSet { updateProgressViews() }
    }
    
    // MARK: - UI Components
    
    // Images
    private let playImage = UIImage(systemName: "play.fill")
    private let pauseImage = UIImage(systemName: "pause.fill")
    private let fullscreenImage = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
    private let exitFullscreenImage = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
    private let backwardImage = UIImage(systemName: "gobackward.10")
    private let forwardImage = UIImage(systemName: "goforward.10")
    private let qualityImage = UIImage(systemName: "list.dash")
    
    // Buttons
    private lazy var playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(pauseImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }()
    
    private lazy var fullscreenButton: UIButton = {
        let button = UIButton()
        button.setImage(fullscreenImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(fullscreenTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }()
    
    private lazy var backwardButton: UIButton = {
        let button = UIButton()
        button.setImage(backwardImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(backwardTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }()
    
    private lazy var forwardButton: UIButton = {
        let button = UIButton()
        button.setImage(forwardImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }()
    
    private lazy var qualityButton: UIButton = {
        let button = UIButton()
        button.setImage(qualityImage, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(qualityTapped), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }()
    
    // Labels
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    // Progress Views
    private lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1.0
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        slider.tintColor = .white
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchUpInside(_:)), for: [.touchUpInside, .touchUpOutside])
        slider.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return slider
    }()
    
    private lazy var bufferedProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressTintColor = UIColor.white.withAlphaComponent(0.5)
        progressView.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        progressView.heightAnchor.constraint(equalToConstant: 2).isActive = true
        return progressView
    }()
    
    // Stack Views
    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [qualityButton, UIView()])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()
    
    private lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            backwardButton,
            playPauseButton,
            forwardButton,
            currentTimeLabel,
            progressSlider,
            durationLabel,
            fullscreenButton
        ])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()
    
    // Gestures
    private lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        return gesture
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupLayout()
        setupGestures()
    }
    
    private func setupLayout() {
        addSubview(topStackView)
        addSubview(bottomStackView)
        addSubview(bufferedProgressView)
        
        // Layout Constraints
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        bufferedProgressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            topStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            bottomStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bottomStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            bufferedProgressView.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            bufferedProgressView.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            bufferedProgressView.centerYAnchor.constraint(equalTo: progressSlider.centerYAnchor)
        ])
        
        bringSubviewToFront(progressSlider)
    }
    
    private func setupGestures() {
        addGestureRecognizer(doubleTapGesture)
        addGestureRecognizer(panGesture)
    }
    
    // MARK: - Public Methods
    func updatePlaybackStatus(isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
    
    func updateFullscreenStatus(isFullscreen: Bool) {
        self.isFullscreen = isFullscreen
    }
    
    func updateTime(currentTime: TimeInterval, duration: TimeInterval) {
        self.currentTime = currentTime
        self.duration = duration
        progressSlider.value = Float(currentTime / duration)
    }
    
    func updateBufferedTime(bufferedTime: TimeInterval) {
        self.bufferedTime = bufferedTime
    }
    
    // MARK: - Private Methods
    private func updateTimeLabels() {
        currentTimeLabel.text = formatTime(seconds: currentTime)
        durationLabel.text = formatTime(seconds: duration)
    }
    
    private func updateProgressViews() {
        let bufferedProgress = Float(bufferedTime / duration)
        bufferedProgressView.setProgress(bufferedProgress, animated: true)
    }
    
    private func formatTime(seconds: TimeInterval) -> String {
        guard !seconds.isNaN else { return "00:00" }
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    @objc private func playPauseTapped() {
        delegate?.controlViewDidTapPlayPause(self)
    }
    
    @objc private func fullscreenTapped() {
        delegate?.controlViewDidTapFullscreen(self)
    }
    
    @objc private func backwardTapped() {
        delegate?.controlViewDidTapBackward(self)
    }
    
    @objc private func forwardTapped() {
        delegate?.controlViewDidTapForward(self)
    }
    
    @objc private func qualityTapped() {
        let quality = VideoQuality(title: "720p", url: URL(string: "https://example.com")!)
        delegate?.controlView(self, didSelectQuality: quality)
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        isSliding = true
        let seekTime = TimeInterval(slider.value) * duration
        currentTimeLabel.text = formatTime(seconds: seekTime)
        delegate?.controlView(self, isSeekingTo: seekTime)
    }
    
    @objc private func sliderTouchUpInside(_ slider: UISlider) {
        isSliding = false
        let seekTime = TimeInterval(slider.value) * duration
        delegate?.controlView(self, didSeekTo: seekTime)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.controlViewDidTapPlayPause(self)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if abs(translation.x) > abs(translation.y) {
            let progress = Float(translation.x / bounds.width)
            let newValue = progressSlider.value + progress
            progressSlider.value = min(max(newValue, 0), 1)
            sliderValueChanged(progressSlider)
            
            if gesture.state == .ended {
                sliderTouchUpInside(progressSlider)
            }
        }
    }
}
