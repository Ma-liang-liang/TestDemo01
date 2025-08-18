import UIKit
import JXSegmentedView

class JXSegmentController: SKBaseController {
    
    // MARK: - Properties
    private let titles: [String]
    
    // UI Elements
    private lazy var segmentedView = JXSegmentedView()
    private lazy var titleDataSource = SegLoadingTitleDataSource()
    private lazy var underlineIndicator = JXSegmentedIndicatorLineView()
    private var listContainerView: JXSegmentedListContainerView!
    
    // The current implementation looks correct, but ensure the child controllers array is properly typed:
    private var childControllers: [UIViewController & JXSegmentedListContainerViewListDelegate] = []
    
//    override var needNavBar: Bool {
//        false
//    }
    
    // In setupChildControllers method:
    private func setupChildControllers() {
        childControllers = [
            FollowViewController(),
            HotViewController(), 
            ConnectViewController()
        ]
    }
    
    // MARK: - Initialization
    init(titles: [String] = ["Follow", "Hot", "Connect"]) {
        self.titles = titles
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildControllers()
        setupSegmented()
        setupListContainerView()
    }
    
    // MARK: - Setup Methods
    private func setupSegmented() {
        view.addSubview(segmentedView)
        segmentedView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedView.topAnchor.constraint(equalTo: self.navBar.bottomAnchor),
            segmentedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 配置数据源
        titleDataSource.titles = titles
        titleDataSource.titleNormalColor = UIColor.label.withAlphaComponent(0.6)
        titleDataSource.titleSelectedColor = UIColor.label
        titleDataSource.titleNormalFont = .systemFont(ofSize: 18, weight: .semibold)
        titleDataSource.itemSpacing = 24
        titleDataSource.isItemSpacingAverageEnabled = false
        titleDataSource.loadingStates = Array(repeating: false, count: titles.count)
        
        // 配置指示器
        underlineIndicator.indicatorWidth = 28
        underlineIndicator.indicatorHeight = 3
        underlineIndicator.indicatorColor = .systemBlue
        underlineIndicator.indicatorCornerRadius = 1.5
        underlineIndicator.verticalOffset = 3
        
        segmentedView.dataSource = titleDataSource
        segmentedView.delegate = self
        segmentedView.indicators = [underlineIndicator]
        segmentedView.contentEdgeInsetLeft = 16
        segmentedView.reloadData()
    }
    
    private func setupListContainerView() {
        listContainerView = JXSegmentedListContainerView(dataSource: self)
        
        view.addSubview(listContainerView)
        listContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            listContainerView.topAnchor.constraint(equalTo: segmentedView.bottomAnchor),
            listContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        segmentedView.listContainer = listContainerView
    }
    
    // MARK: - Public Methods
    func startLoadingOnTab(_ index: Int) {
        guard index < titleDataSource.loadingStates.count else { return }
        titleDataSource.loadingStates[index] = true
        segmentedView.reloadItem(at: index)
        
        if segmentedView.selectedIndex == index {
            underlineIndicator.isHidden = true
        }
    }
    
    func stopLoadingOnTab(_ index: Int) {
        guard index < titleDataSource.loadingStates.count else { return }
        titleDataSource.loadingStates[index] = false
        segmentedView.reloadItem(at: index)
        
        if segmentedView.selectedIndex == index {
            underlineIndicator.isHidden = false
        }
    }
    
    func selectTab(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < titles.count else { return }
        segmentedView.selectItemAt(index: index)
    }
}

// MARK: - JXSegmentedListContainerViewDataSource
extension JXSegmentController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        return titles.count
    }
    
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        return childControllers[index]
    }
}

// MARK: - JXSegmentedViewDelegate
extension JXSegmentController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, index < self.childControllers.count else { return }
            // 处理选中逻辑
        }
    }
    
    func segmentedView(_ segmentedView: JXSegmentedView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) {
        // 处理滚动逻辑
    }
    
    func segmentedView(_ segmentedView: JXSegmentedView, didScrollSelectedItemAt index: Int) {
        // 处理滚动完成逻辑
    }
}

// MARK: - Custom Cell Classes
open class SegLoadingTitleItemModel: JXSegmentedTitleItemModel {
    open var isLoading: Bool = false
}

open class SegLoadingTitleCell: JXSegmentedTitleCell {
    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        v.color = .systemGray
        return v
    }()
    private var lastIsLoading: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(spinner)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = CGPoint(x: bounds.width - 15, y: bounds.height / 2)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        spinner.stopAnimating()
        lastIsLoading = false
    }

    open override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType)
        
        guard let model = itemModel as? SegLoadingTitleItemModel else { return }
        
        if model.isLoading != lastIsLoading {
            lastIsLoading = model.isLoading
            if model.isLoading {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        }
    }
}

open class SegLoadingTitleDataSource: JXSegmentedTitleDataSource {
    public var loadingStates: [Bool] = []

    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return SegLoadingTitleItemModel()
    }

    open override func reloadData(selectedIndex: Int) {
        super.reloadData(selectedIndex: selectedIndex)
        loadingStates = Array(repeating: false, count: titles.count)
    }

    open override func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
        
        guard let model = itemModel as? SegLoadingTitleItemModel,
              index < loadingStates.count else { return }
        
        model.isLoading = loadingStates[index]
    }

    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(SegLoadingTitleCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! SegLoadingTitleCell
        return cell
    }
}
