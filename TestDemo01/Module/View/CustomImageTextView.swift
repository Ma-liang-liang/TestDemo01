////
////  CustomImageTextView.swift
////  TestDemo
////
////  Created by 马亮亮 on 2025/6/5.
////
//
//import UIKit
//
//// 图片相对于文字的位置枚举
//enum ImagePosition {
//    case top, bottom, left, right
//}
//
//// 自定义图片文字组合视图
//class CustomImageTextView: UIView {
//    
//    // MARK: - UI Components
//    private let imageView = UIImageView()
//    private let label = UILabel()
//    private let stackView = UIStackView()
//    
//    // MARK: - Properties
//    var imagePosition: ImagePosition = .top {
//        didSet {
//            updateLayout()
//        }
//    }
//    
//    var spacing: CGFloat = 8 {
//        didSet {
//            stackView.spacing = spacing
//        }
//    }
//    
//    var contentPadding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
//        didSet {
//            updateContentPadding()
//        }
//    }
//    
//    var imageSize: CGSize = CGSize(width: 50, height: 50) {
//        didSet {
//            updateImageSize()
//        }
//    }
//    
//    var text: String? {
//        get { return label.text }
//        set { label.text = newValue }
//    }
//    
//    var image: UIImage? {
//        get { return imageView.image }
//        set { imageView.image = newValue }
//    }
//    
//    var textColor: UIColor {
//        get { return label.textColor }
//        set { label.textColor = newValue }
//    }
//    
//    var font: UIFont {
//        get { return label.font }
//        set { label.font = newValue }
//    }
//    
//    // MARK: - Constraints
//    private var imageWidthConstraint: NSLayoutConstraint!
//    private var imageHeightConstraint: NSLayoutConstraint!
//    private var stackViewTopConstraint: NSLayoutConstraint!
//    private var stackViewLeadingConstraint: NSLayoutConstraint!
//    private var stackViewTrailingConstraint: NSLayoutConstraint!
//    private var stackViewBottomConstraint: NSLayoutConstraint!
//    
//    // MARK: - Initializers
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupUI()
//    }
//    
//    convenience init(image: UIImage?, text: String?) {
//        self.init(frame: .zero)
//        self.image = image
//        self.text = text
//    }
//    
//    convenience init(imageName: String, text: String?) {
//        self.init(frame: .zero)
//        self.image = UIImage(named: imageName)
//        self.text = text
//    }
//    
//    convenience init(systemImageName: String, text: String?) {
//        self.init(frame: .zero)
//        self.image = UIImage(systemName: systemImageName)
//        self.text = text
//    }
//    
//    // MARK: - Setup
//    private func setupUI() {
//        setupImageView()
//        setupLabel()
//        setupStackView()
//        setupConstraints()
//    }
//    
//    private func setupImageView() {
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//    }
//    
//    private func setupLabel() {
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.textColor = .label
//        label.font = UIFont.systemFont(ofSize: 16)
//        label.translatesAutoresizingMaskIntoConstraints = false
//    }
//    
//    private func setupStackView() {
//        stackView.axis = .vertical
//        stackView.alignment = .center
//        stackView.distribution = .fill
//        stackView.spacing = spacing
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        addSubview(stackView)
//        updateLayout()
//    }
//    
//    private func setupConstraints() {
//        // 图片尺寸约束
//        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageSize.width)
//        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
//        imageWidthConstraint.isActive = true
//        imageHeightConstraint.isActive = true
//        
//        // StackView约束
//        stackViewTopConstraint = stackView.topAnchor.constraint(equalTo: topAnchor, constant: contentPadding.top)
//        stackViewLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentPadding.left)
//        stackViewTrailingConstraint = trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: contentPadding.right)
//        stackViewBottomConstraint = bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: contentPadding.bottom)
//        
//        NSLayoutConstraint.activate([
//            stackViewTopConstraint,
//            stackViewLeadingConstraint,
//            stackViewTrailingConstraint,
//            stackViewBottomConstraint
//        ])
//    }
//    
//    // MARK: - Layout Updates
//    private func updateLayout() {
//        // 清空StackView
//        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//        
//        // 根据imagePosition重新添加子视图
//        switch imagePosition {
//        case .top:
//            stackView.axis = .vertical
//            stackView.addArrangedSubview(imageView)
//            stackView.addArrangedSubview(label)
//        case .bottom:
//            stackView.axis = .vertical
//            stackView.addArrangedSubview(label)
//            stackView.addArrangedSubview(imageView)
//        case .left:
//            stackView.axis = .horizontal
//            stackView.addArrangedSubview(imageView)
//            stackView.addArrangedSubview(label)
//        case .right:
//            stackView.axis = .horizontal
//            stackView.addArrangedSubview(label)
//            stackView.addArrangedSubview(imageView)
//        }
//    }
//    
//    private func updateImageSize() {
//        imageWidthConstraint.constant = imageSize.width
//        imageHeightConstraint.constant = imageSize.height
//        layoutIfNeeded()
//    }
//    
//    private func updateContentPadding() {
//        stackViewTopConstraint.constant = contentPadding.top
//        stackViewLeadingConstraint.constant = contentPadding.left
//        stackViewTrailingConstraint.constant = contentPadding.right
//        stackViewBottomConstraint.constant = contentPadding.bottom
//        layoutIfNeeded()
//    }
//}
//
//// MARK: - Convenience Methods
//extension CustomImageTextView {
//    
//    @discardableResult
//    func setImagePosition(_ position: ImagePosition) -> Self {
//        imagePosition = position
//        return self
//    }
//    
//    @discardableResult
//    func setSpacing(_ spacing: CGFloat) -> Self {
//        self.spacing = spacing
//        return self
//    }
//    
//    @discardableResult
//    func setContentPadding(_ padding: UIEdgeInsets) -> Self {
//        contentPadding = padding
//        return self
//    }
//    
//    @discardableResult
//    func setContentPadding(_ padding: CGFloat) -> Self {
//        contentPadding = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
//        return self
//    }
//    
//    @discardableResult
//    func setImageSize(_ size: CGSize) -> Self {
//        imageSize = size
//        return self
//    }
//    
//    @discardableResult
//    func setImageSize(_ size: CGFloat) -> Self {
//        imageSize = CGSize(width: size, height: size)
//        return self
//    }
//    
//    @discardableResult
//    func setTextColor(_ color: UIColor) -> Self {
//        textColor = color
//        return self
//    }
//    
//    @discardableResult
//    func setFont(_ font: UIFont) -> Self {
//        self.font = font
//        return self
//    }
//    
//    @discardableResult
//    func setText(_ text: String?) -> Self {
//        self.text = text
//        return self
//    }
//    
//    @discardableResult
//    func setImage(_ image: UIImage?) -> Self {
//        self.image = image
//        return self
//    }
//    
//    @discardableResult
//    func setImage(named imageName: String) -> Self {
//        image = UIImage(named: imageName)
//        return self
//    }
//    
//    @discardableResult
//    func setImage(systemName: String) -> Self {
//        image = UIImage(systemName: systemName)
//        return self
//    }
//}
//
import UIKit

// 图片相对于文字的位置枚举
enum ImagePosition {
    case top, bottom, left, right
}

// 图片加载状态枚举
enum ImageLoadState {
    case idle
    case loading
    case success
    case failed
}

// 自定义图片文字组合视图
class CustomImageTextView: UIView {
    
    // MARK: - UI Components
    private let imageView = UIImageView()
    private let label = UILabel()
    private let stackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    var imagePosition: ImagePosition = .top {
        didSet {
            updateLayout()
        }
    }
    
    var spacing: CGFloat = 8 {
        didSet {
            stackView.spacing = spacing
        }
    }
    
    var contentPadding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet {
            updateContentPadding()
        }
    }
    
    var imageSize: CGSize = CGSize(width: 50, height: 50) {
        didSet {
            updateImageSize()
        }
    }
    
    var text: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            imageLoadState = newValue != nil ? .success : .idle
        }
    }
    
    var textColor: UIColor {
        get { return label.textColor }
        set { label.textColor = newValue }
    }
    
    var font: UIFont {
        get { return label.font }
        set { label.font = newValue }
    }
    
    // 占位图
    var placeholderImage: UIImage? = UIImage(systemName: "photo")
    
    // 加载失败时的默认图片
    var errorImage: UIImage? = UIImage(systemName: "exclamationmark.triangle")
    
    // 图片加载状态
    private var imageLoadState: ImageLoadState = .idle {
        didSet {
            updateImageLoadState()
        }
    }
    
    // 选中状态
    var isSelected: Bool = false {
        didSet {
            updateSelectedState()
        }
    }
    
    // 选中状态样式配置
    var selectedBackgroundColor: UIColor?
    var selectedTextColor: UIColor?
    var selectedBorderColor: UIColor?
    var selectedBorderWidth: CGFloat = 0
    var selectedCornerRadius: CGFloat?
    var selectedAlpha: CGFloat = 1.0
    var selectedTransform: CGAffineTransform = .identity
    
    // 非选中状态样式配置
    var normalBackgroundColor: UIColor?
    var normalTextColor: UIColor?
    var normalBorderColor: UIColor?
    var normalBorderWidth: CGFloat = 0
    var normalCornerRadius: CGFloat?
    var normalAlpha: CGFloat = 1.0
    var normalTransform: CGAffineTransform = .identity
    
    // 选中状态变化动画
    var selectionAnimationDuration: TimeInterval = 0.2
    var selectionAnimationOptions: UIView.AnimationOptions = [.curveEaseInOut]
    
    // 点击事件回调
    var onTap: ((CustomImageTextView) -> Void)?
    var onImageTap: (() -> Void)?
    var onTextTap: (() -> Void)?
    var onSelectionChanged: ((Bool) -> Void)?  // 选中状态变化回调
    
    // 网络请求任务
    private var imageLoadTask: URLSessionDataTask?
    
    // MARK: - Constraints
    private var imageWidthConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    private var stackViewTopConstraint: NSLayoutConstraint!
    private var stackViewLeadingConstraint: NSLayoutConstraint!
    private var stackViewTrailingConstraint: NSLayoutConstraint!
    private var stackViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(image: UIImage?, text: String?) {
        self.init(frame: .zero)
        self.image = image
        self.text = text
    }
    
    convenience init(imageName: String, text: String?) {
        self.init(frame: .zero)
        self.image = UIImage(named: imageName)
        self.text = text
    }
    
    convenience init(systemImageName: String, text: String?) {
        self.init(frame: .zero)
        self.image = UIImage(systemName: systemImageName)
        self.text = text
    }
    
    convenience init(imageURL: String, text: String?) {
        self.init(frame: .zero)
        self.text = text
        loadImage(from: imageURL)
    }
    
    convenience init(imageURL: URL, text: String?) {
        self.init(frame: .zero)
        self.text = text
        loadImage(from: imageURL)
    }
    
    deinit {
        imageLoadTask?.cancel()
    }
    
    // MARK: - Setup
    private func setupUI() {
        setupImageView()
        setupLabel()
        setupActivityIndicator()
        setupStackView()
        setupConstraints()
        setupGestureRecognizers()
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
    }
    
    private func setupLabel() {
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemGray
    }
    
    private func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        updateLayout()
    }
    
    private func setupConstraints() {
        // 图片尺寸约束
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageSize.width)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        imageWidthConstraint.isActive = true
        imageHeightConstraint.isActive = true
        
        // 活动指示器约束
        imageView.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        
        // StackView约束
        stackViewTopConstraint = stackView.topAnchor.constraint(equalTo: topAnchor, constant: contentPadding.top)
        stackViewLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentPadding.left)
        stackViewTrailingConstraint = trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: contentPadding.right)
        stackViewBottomConstraint = bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: contentPadding.bottom)
        
        NSLayoutConstraint.activate([
            stackViewTopConstraint,
            stackViewLeadingConstraint,
            stackViewTrailingConstraint,
            stackViewBottomConstraint
        ])
    }
    
    private func setupGestureRecognizers() {
        // 整体点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        // 图片点击手势
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        imageView.addGestureRecognizer(imageTapGesture)
        
        // 文字点击手势
        let textTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTextTap))
        label.addGestureRecognizer(textTapGesture)
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleTap() {
        onTap?(self)
    }
    
    @objc private func handleImageTap() {
        onImageTap?()
    }
    
    @objc private func handleTextTap() {
        onTextTap?()
    }
    
    // MARK: - Selection State
    func setSelectedStyle(_ selected: Bool, animated: Bool = true) {
        let shouldAnimate = animated && selected != isSelected
        isSelected = selected
        
        if shouldAnimate {
            updateSelectedStateAnimated()
        } else {
            updateSelectedState()
        }
    }
    
    func toggleSelection(animated: Bool = true) {
        setSelectedStyle(!isSelected, animated: animated)
    }
    
    private func updateSelectedState() {
        updateSelectedStateAnimated(duration: 0)
    }
    
    private func updateSelectedStateAnimated(duration: TimeInterval? = nil) {
        let animationDuration = duration ?? selectionAnimationDuration
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: selectionAnimationOptions,
            animations: { [weak self] in
                self?.applySelectedStyle()
            },
            completion: { [weak self] _ in
                self?.onSelectionChanged?(self?.isSelected ?? false)
            }
        )
    }
    
    private func applySelectedStyle() {
        if isSelected {
            // 应用选中状态样式
            if let bgColor = selectedBackgroundColor {
                backgroundColor = bgColor
            }
            if let textColor = selectedTextColor {
                label.textColor = textColor
            }
            if let borderColor = selectedBorderColor {
                layer.borderColor = borderColor.cgColor
            }
            layer.borderWidth = selectedBorderWidth
            if let cornerRadius = selectedCornerRadius {
                layer.cornerRadius = cornerRadius
            }
            alpha = selectedAlpha
            transform = selectedTransform
        } else {
            // 应用正常状态样式
            if let bgColor = normalBackgroundColor {
                backgroundColor = bgColor
            }
            if let textColor = normalTextColor {
                label.textColor = textColor
            }
            if let borderColor = normalBorderColor {
                layer.borderColor = borderColor.cgColor
            }
            layer.borderWidth = normalBorderWidth
            if let cornerRadius = normalCornerRadius {
                layer.cornerRadius = cornerRadius
            }
            alpha = normalAlpha
            transform = normalTransform
        }
    }
    
    // MARK: - Layout Updates
    private func updateLayout() {
        // 清空StackView
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 根据imagePosition重新添加子视图
        switch imagePosition {
        case .top:
            stackView.axis = .vertical
            stackView.addArrangedSubview(imageView)
            stackView.addArrangedSubview(label)
        case .bottom:
            stackView.axis = .vertical
            stackView.addArrangedSubview(label)
            stackView.addArrangedSubview(imageView)
        case .left:
            stackView.axis = .horizontal
            stackView.addArrangedSubview(imageView)
            stackView.addArrangedSubview(label)
        case .right:
            stackView.axis = .horizontal
            stackView.addArrangedSubview(label)
            stackView.addArrangedSubview(imageView)
        }
    }
    
    private func updateImageSize() {
        imageWidthConstraint.constant = imageSize.width
        imageHeightConstraint.constant = imageSize.height
        layoutIfNeeded()
    }
    
    private func updateContentPadding() {
        stackViewTopConstraint.constant = contentPadding.top
        stackViewLeadingConstraint.constant = contentPadding.left
        stackViewTrailingConstraint.constant = contentPadding.right
        stackViewBottomConstraint.constant = contentPadding.bottom
        layoutIfNeeded()
    }
    
    private func updateImageLoadState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch self.imageLoadState {
            case .idle:
                self.activityIndicator.stopAnimating()
            case .loading:
                self.imageView.image = self.placeholderImage
                self.activityIndicator.startAnimating()
            case .success:
                self.activityIndicator.stopAnimating()
            case .failed:
                self.activityIndicator.stopAnimating()
                self.imageView.image = self.errorImage
            }
        }
    }
    
    // MARK: - Network Image Loading
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            imageLoadState = .failed
            return
        }
        loadImage(from: url)
    }
    
    func loadImage(from url: URL) {
        // 取消之前的请求
        imageLoadTask?.cancel()
        
        imageLoadState = .loading
        
        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Image load error: \(error.localizedDescription)")
                self.imageLoadState = .failed
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                self.imageLoadState = .failed
                return
            }
            
            DispatchQueue.main.async {
                self.imageView.image = image
                self.imageLoadState = .success
            }
        }
        
        imageLoadTask?.resume()
    }
    
    // 清除图片缓存并重新加载
    func reloadImage() {
        if let task = imageLoadTask {
            task.cancel()
            if let url = task.originalRequest?.url {
                loadImage(from: url)
            }
        }
    }
}

// MARK: - Convenience Methods
extension CustomImageTextView {
    
    @discardableResult
    func setImagePosition(_ position: ImagePosition) -> Self {
        imagePosition = position
        return self
    }
    
    @discardableResult
    func setSpacing(_ spacing: CGFloat) -> Self {
        self.spacing = spacing
        return self
    }
    
    @discardableResult
    func setContentPadding(_ padding: UIEdgeInsets) -> Self {
        contentPadding = padding
        return self
    }
    
    @discardableResult
    func setContentPadding(_ padding: CGFloat) -> Self {
        contentPadding = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        return self
    }
    
    @discardableResult
    func setImageSize(_ size: CGSize) -> Self {
        imageSize = size
        return self
    }
    
    @discardableResult
    func setImageSize(_ size: CGFloat) -> Self {
        imageSize = CGSize(width: size, height: size)
        return self
    }
    
    @discardableResult
    func setTextColor(_ color: UIColor) -> Self {
        textColor = color
        return self
    }
    
    @discardableResult
    func setFont(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func setText(_ text: String?) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult
    func setImage(_ image: UIImage?) -> Self {
        self.image = image
        return self
    }
    
    @discardableResult
    func setImage(named imageName: String) -> Self {
        image = UIImage(named: imageName)
        return self
    }
    
    @discardableResult
    func setImage(systemName: String) -> Self {
        image = UIImage(systemName: systemName)
        return self
    }
    
    @discardableResult
    func setImageURL(_ urlString: String) -> Self {
        loadImage(from: urlString)
        return self
    }
    
    @discardableResult
    func setImageURL(_ url: URL) -> Self {
        loadImage(from: url)
        return self
    }
    
    @discardableResult
    func setPlaceholderImage(_ image: UIImage?) -> Self {
        placeholderImage = image
        return self
    }
    
    @discardableResult
    func setErrorImage(_ image: UIImage?) -> Self {
        errorImage = image
        return self
    }
    
    // MARK: - Selection State Configuration
    @discardableResult
    func setSelected(_ selected: Bool, animated: Bool = true) -> Self {
        setSelected(selected, animated: animated)
        return self
    }
    
    @discardableResult
    func setSelectedBackgroundColor(_ color: UIColor?) -> Self {
        selectedBackgroundColor = color
        return self
    }
    
    @discardableResult
    func setSelectedTextColor(_ color: UIColor?) -> Self {
        selectedTextColor = color
        return self
    }
    
    @discardableResult
    func setSelectedBorderColor(_ color: UIColor?) -> Self {
        selectedBorderColor = color
        return self
    }
    
    @discardableResult
    func setSelectedBorderWidth(_ width: CGFloat) -> Self {
        selectedBorderWidth = width
        return self
    }
    
    @discardableResult
    func setSelectedCornerRadius(_ radius: CGFloat) -> Self {
        selectedCornerRadius = radius
        return self
    }
    
    @discardableResult
    func setSelectedAlpha(_ alpha: CGFloat) -> Self {
        selectedAlpha = alpha
        return self
    }
    
    @discardableResult
    func setSelectedTransform(_ transform: CGAffineTransform) -> Self {
        selectedTransform = transform
        return self
    }
    
    @discardableResult
    func setNormalBackgroundColor(_ color: UIColor?) -> Self {
        normalBackgroundColor = color
        return self
    }
    
    @discardableResult
    func setNormalTextColor(_ color: UIColor?) -> Self {
        normalTextColor = color
        return self
    }
    
    @discardableResult
    func setNormalBorderColor(_ color: UIColor?) -> Self {
        normalBorderColor = color
        return self
    }
    
    @discardableResult
    func setNormalBorderWidth(_ width: CGFloat) -> Self {
        normalBorderWidth = width
        return self
    }
    
    @discardableResult
    func setNormalCornerRadius(_ radius: CGFloat) -> Self {
        normalCornerRadius = radius
        return self
    }
    
    @discardableResult
    func setNormalAlpha(_ alpha: CGFloat) -> Self {
        normalAlpha = alpha
        return self
    }
    
    @discardableResult
    func setNormalTransform(_ transform: CGAffineTransform) -> Self {
        normalTransform = transform
        return self
    }
    
    @discardableResult
    func setSelectionAnimationDuration(_ duration: TimeInterval) -> Self {
        selectionAnimationDuration = duration
        return self
    }
    
    @discardableResult
    func setSelectionAnimationOptions(_ options: UIView.AnimationOptions) -> Self {
        selectionAnimationOptions = options
        return self
    }
    
    // MARK: - Event Handlers
    @discardableResult
    func onTap(_ handler: @escaping (CustomImageTextView) -> Void) -> Self {
        onTap = handler
        return self
    }
    
    @discardableResult
    func onImageTap(_ handler: @escaping () -> Void) -> Self {
        onImageTap = handler
        return self
    }
    
    @discardableResult
    func onTextTap(_ handler: @escaping () -> Void) -> Self {
        onTextTap = handler
        return self
    }
    
    @discardableResult
    func onSelectionChanged(_ handler: @escaping (Bool) -> Void) -> Self {
        onSelectionChanged = handler
        return self
    }
}

