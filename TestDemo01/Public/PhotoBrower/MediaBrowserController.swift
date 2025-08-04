//
//  MediaBrowserController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/14.
//

import UIKit
import SnapKit
import Kingfisher
import AVKit

// MARK: - 数据模型
enum MediaType {
    case image
    case gif
    case video
}

struct MediaResource {
    let url: String
    let type: MediaType
    let thumbnail: UIImage? // 视频缩略图
    var placeholder: UIImage? = UIImage(named: "default_placeholder")
}

// MARK: - 协议定义
protocol MediaBrowserDelegate: AnyObject {
    func didTapMedia(at index: Int)
    func didDoubleTapMedia(at index: Int)
    func didLongPressMedia(at index: Int)
    func didRotateMedia(at index: Int)
    func didZoomMedia(at index: Int, scale: CGFloat)
}

// MARK: - 主控制器
class MediaBrowserViewController: UIViewController {
       
    // MARK: - 属性
    private var resources: [MediaResource] = []
    private var currentIndex: Int = 0
    private weak var delegate: MediaBrowserDelegate?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        cv.register(VideoCell.self, forCellWithReuseIdentifier: "VideoCell")
        cv.backgroundColor = .white
        return cv
    }()
    
    private let backgroundView = UIView()
    
    private lazy var navigationBar: SKNavigationBar = {
        let view = SKNavigationBar()
        view.backgroundColor = .white
        view.backBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.titleLabel.text = "相册"
        return view
    }()
    private var isDragging = false
    private var originalFrame: CGRect = .zero
    
    // MARK: - 初始化
    convenience init(resources: [MediaResource], currentIndex: Int = 0, delegate: MediaBrowserDelegate? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.resources = resources
        self.currentIndex = currentIndex
        self.delegate = delegate
        modalPresentationStyle = .fullScreen
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = .clear
        

        // 集合视图
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        
        // 导航栏
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        navigationBar.backBtn.isUserInteractionEnabled = true
        navigationBar.container.backgroundColor = .clear
        navigationBar.backgroundColor = .clear
        navigationBar.backBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)

    }
    
    // MARK: - 手势处理
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        collectionView.addGestureRecognizer(pan)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cell = currentCell else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            originalFrame = cell.imageView.frame
            isDragging = true
        case .changed:
            let progress = translation.y / view.bounds.height
            backgroundView.alpha = 1 - abs(progress)
            
            cell.imageView.center = CGPoint(
                x: cell.imageView.center.x + translation.x,
                y: cell.imageView.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: view)
        case .ended, .cancelled:
            isDragging = false
            let shouldDismiss = abs(translation.y) > 30 || abs(velocity.y) > 500
            if shouldDismiss {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.25) {
                    cell.imageView.frame = self.originalFrame
                    self.backgroundView.alpha = 1
                }
            }
        default: break
        }
    }
    
    // MARK: - 当前Cell
    private var currentCell: ImageCell? {
        let indexPath = IndexPath(item: currentIndex, section: 0)
        return collectionView.cellForItem(at: indexPath) as? ImageCell
    }
    
    @objc private func closeAction() {
        dismiss(animated: true)
    }
}

// MARK: - CollectionView数据源
extension MediaBrowserViewController: UICollectionViewDataSource {
   
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let resource = resources[indexPath.item]
        
        switch resource.type {
        case .image, .gif:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
            cell.configure(with: resource)
            cell.imageView.backgroundColor = .random
            cell.imageView.image = UIImage(named: "img001")?.resized(toWidth: UIScreen.kScreenWidth)
            return cell
        case .video:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
            cell.configure(with: resource)
            cell.backgroundColor = .random

            return cell
        }
    }
}

// MARK: - CollectionView代理
extension MediaBrowserViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
    }
}



// MARK: - 视频控制条
class VideoControlBar: UIView {
    let playButton = UIButton()
    let progressView = UIProgressView()
    let timeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        playButton.setImage(UIImage(named: "play_icon"), for: .normal)
        addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }
        
        addSubview(timeLabel)
        timeLabel.textColor = .white
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.equalTo(playButton.snp.right).offset(16)
            make.right.equalTo(timeLabel.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MediaBrowserViewController: MediaBrowserDelegate {
    
    func didTapMedia(at index: Int) {
        
    }
    
    func didDoubleTapMedia(at index: Int) {
        
    }
    
    func didLongPressMedia(at index: Int) {
        
    }
    
    func didRotateMedia(at index: Int) {
        
    }
    
    func didZoomMedia(at index: Int, scale: CGFloat) {
        
    }
}

// MARK: - 使用示例
/*
let resources = [
    MediaResource(url: imageURL, type: .image),
    MediaResource(url: videoURL, type: .video, thumbnail: thumbnailImage),
    MediaResource(url: gifURL, type: .gif)
]

let browser = MediaBrowserViewController(resources: resources, currentIndex: 0)
present(browser, animated: true)
*/
