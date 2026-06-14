//
//  ALCollectionController.swift
//  TestDemo
//
//  Created by maliangliang on 2025/7/8.
//

import UIKit


class ALCollectionController: SKBaseController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.insertSubview(collectionView, at: 0)
        
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        collectionView.register(cellWithClass: LabelCell.self)
        
    }
    
   
    func getLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.kScreenWidth, height: UIScreen.kScreenHeight)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        return layout
    }
   
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: getLayout())
        view.backgroundColor = .white
        view.showsVerticalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        view.isPagingEnabled = true
        return view
    }()
    
    

}

extension ALCollectionController: UICollectionViewDataSource, UICollectionViewDelegate {
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withClass: LabelCell.self, for: indexPath)
        cell.textLabel.text = "\(indexPath.item)"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        print("didEndDisplaying  \(indexPath.item)")
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("willDisplay  \(indexPath.item)")
    }
    
}


extension ALCollectionController {
    
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
            
            backgroundColor = .random
        }
        
        lazy var textLabel: UILabel = {
            let label = UILabel()
            label.textAlignment = .center
            return label
        }()
    }
}
