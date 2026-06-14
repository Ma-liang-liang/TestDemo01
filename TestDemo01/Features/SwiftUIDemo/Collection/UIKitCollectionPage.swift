import UIKit
import SwiftUI

// MARK: - 1. SwiftUI View for Cell Content
struct SimpleSwiftUICellContent: View {
    var index: Int
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading) {
                Text("SwiftUI Item \(index)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("This is a SwiftUI View inside a UIKit Cell")
                    .font(.subheadline)
                    .foregroundStyle(.pink)
            }
            
            Spacer()
            
            Button(action: {
                print("Button tapped at index: \(index)")
            }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.brown)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 2. UIKit View Controller
class UIKitCollectionPage: UIViewController, UICollectionViewDataSource {
    
    var collectionView: UICollectionView!
    let cellId = "cellId"
    let legacyCellId = "legacyCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "UIKit Collection + SwiftUI"
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        // 使用 Compositional Layout
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100) // 自适应高度
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 10
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            
            return section
        }
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        
        // 注册 Cell
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        // 使用通用的 SwiftUIBaseCollectionViewCell
        collectionView.register(SwiftUIBaseCollectionViewCell.self, forCellWithReuseIdentifier: legacyCellId)
        
        view.addSubview(collectionView)
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 使用 UIHostingConfiguration 将 SwiftUI View 嵌入 Cell (iOS 16+)
        if #available(iOS 16.0, *) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
            cell.contentConfiguration = UIHostingConfiguration {
                SimpleSwiftUICellContent(index: indexPath.item)
            }
            // 去除默认背景，由 SwiftUI View 控制，或者保持默认
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
            return cell
        } else {
            // Fallback for older iOS versions: 使用通用的 SwiftUIBaseCollectionViewCell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legacyCellId, for: indexPath) as! SwiftUIBaseCollectionViewCell
            cell.setContent(view: SimpleSwiftUICellContent(index: indexPath.item), parentViewController: self)
            return cell
        }
    }
}

// MARK: - 3. Wrapper for SwiftUI Preview & Usage
struct UIKitCollectionPageWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitCollectionPage {
        return UIKitCollectionPage()
    }
    
    func updateUIViewController(_ uiViewController: UIKitCollectionPage, context: Context) {
        // Update logic if needed
    }
}

#Preview {
    UIKitCollectionPageWrapper()
}
