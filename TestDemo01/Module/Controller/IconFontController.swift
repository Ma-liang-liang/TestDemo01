//
//  IconFontController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/4/25.
//

import UIKit
import SwifterSwift

class IconFontController: SKBaseController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews {
            collectionView
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        collectionView.register(cellWithClass: ImageCell.self)
        collectionView.register(cellWithClass: LabelCell.self)
        
        manualPerformanceTest()
    }
    
    func manualPerformanceTest() {
        let iterations = 1000
        
        // UILabel 测试
        var startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
//            let label = UILabel()
//            label.setIcon(AppIcon.arrow_left.rawValue, size: 24, color: .red)
            _ = SystemIcon.getIcon(icon: .arrowLeft)

        }
        let labelTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // 毫秒
        
        // UIImage 测试
        startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = IconFontManager.icon(AppIcon.arrow_left.rawValue, size: 24)
        }
        let imageTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        print("SystemIcon 耗时: \(labelTime)ms, UIImage 耗时: \(imageTime)ms")
    }
    
    func getLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(horizontal: 16, vertical: 8)
        return layout
    }
   
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: getLayout())
        view.backgroundColor = .white
        view.showsVerticalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    

}

extension IconFontController: UICollectionViewDataSource, UICollectionViewDelegate {
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: ImageCell.self, for: indexPath)
            cell.imageView.image = AppIcon.arrow_left.image(color: .random)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: LabelCell.self, for: indexPath)
        cell.textLabel.setIcon(AppIcon.refresh.rawValue, size: 36, color: .random)
        return cell
    }
    
    
}

extension IconFontController {
    
    class ImageCell: UICollectionViewCell {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            makeUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func makeUI() {
            
            contentView.addSubview(imageView)
            
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            backgroundColor = .cyan.withAlphaComponent(0.2)
        }
        
        lazy var imageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            return view
        }()
    }
}

extension IconFontController {
    
    class LabelCell: UICollectionViewCell {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            makeUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func makeUI() {
            
            contentView.addSubview(textLabel)
            
            textLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            backgroundColor = .yellow.withAlphaComponent(0.2)
        }
        
        lazy var textLabel: UILabel = {
            let label = UILabel()
            return label
        }()
    }
}
