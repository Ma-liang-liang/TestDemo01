//
//  UIScrollView+Chain.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UIScrollView {
    @discardableResult
    func cg_contentOffset(_ contentOffset: CGPoint) -> Self {
        self.contentOffset = contentOffset
        return self
    }
    
    @discardableResult
    func cg_contentSize(_ contentSize: CGSize) -> Self {
        self.contentSize = contentSize
        return self
    }
    
    @discardableResult
    func cg_contentInset(_ left: CGFloat? = nil, right: CGFloat? = nil,
                         top: CGFloat? = nil, bottom: CGFloat? = nil) -> Self {
        if let left {
            contentInset.left = left
        }
        
        if let right {
            contentInset.right = right
        }
        
        if let top {
            contentInset.top = top
        }
        
        if let bottom {
            contentInset.bottom = bottom
        }
        return self
    }
    
    @discardableResult
    func cg_isPagingEnabled(_ isPagingEnabled: Bool) -> Self {
        self.isPagingEnabled = isPagingEnabled
        return self
    }
    
    @discardableResult
    func cg_isScrollEnabled(_ isScrollEnabled: Bool) -> Self {
        self.isScrollEnabled = isScrollEnabled
        return self
    }
    
    @discardableResult
    func cg_showsHorizontalScrollIndicator(_ showsHorizontalScrollIndicator: Bool) -> Self {
        self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        return self
    }
    
    @discardableResult
    func cg_showsVerticalScrollIndicator(_ showsVerticalScrollIndicator: Bool) -> Self {
        self.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        return self
    }
    
    @discardableResult
    func cg_bounces(_ bounces: Bool) -> Self {
        self.bounces = bounces
        return self
    }
    
    @discardableResult
    func cg_alwaysBounceHorizontal(_ alwaysBounceHorizontal: Bool) -> Self {
        self.alwaysBounceHorizontal = alwaysBounceHorizontal
        return self
    }
    
    @discardableResult
    func cg_alwaysBounceVertical(_ alwaysBounceVertical: Bool) -> Self {
        self.alwaysBounceVertical = alwaysBounceVertical
        return self
    }
    
    @discardableResult
    func cg_delegate(_ delegate: UIScrollViewDelegate?) -> Self {
        self.delegate = delegate
        return self
    }
    
    @discardableResult
    func cg_indicatorStyle(_ indicatorStyle: UIScrollView.IndicatorStyle) -> Self {
        self.indicatorStyle = indicatorStyle
        return self
    }
    
    @discardableResult
    func cg_scrollIndicatorInsets(_ scrollIndicatorInsets: UIEdgeInsets) -> Self {
        self.scrollIndicatorInsets = scrollIndicatorInsets
        return self
    }
    
    @discardableResult
    func cg_zoomScale(_ zoomScale: CGFloat, animated: Bool = false) -> Self {
        self.setZoomScale(zoomScale, animated: animated)
        return self
    }
    
    @discardableResult
    func cg_maximumZoomScale(_ maximumZoomScale: CGFloat) -> Self {
        self.maximumZoomScale = maximumZoomScale
        return self
    }
    
    @discardableResult
    func cg_minimumZoomScale(_ minimumZoomScale: CGFloat) -> Self {
        self.minimumZoomScale = minimumZoomScale
        return self
    }
    
    @discardableResult
    func cg_bouncesZoom(_ bouncesZoom: Bool) -> Self {
        self.bouncesZoom = bouncesZoom
        return self
    }
    
    @discardableResult
    func cg_scrollsToTop(_ scrollsToTop: Bool) -> Self {
        self.scrollsToTop = scrollsToTop
        return self
    }
    
    @discardableResult
    func cg_keyboardDismissMode(_ keyboardDismissMode: UIScrollView.KeyboardDismissMode) -> Self {
        self.keyboardDismissMode = keyboardDismissMode
        return self
    }
    
    @discardableResult
    func cg_isDirectionalLockEnabled(_ isDirectionalLockEnabled: Bool) -> Self {
        self.isDirectionalLockEnabled = isDirectionalLockEnabled
        return self
    }
    
    @discardableResult
    func cg_delaysContentTouches(_ delaysContentTouches: Bool) -> Self {
        self.delaysContentTouches = delaysContentTouches
        return self
    }
    
    @discardableResult
    func cg_canCancelContentTouches(_ canCancelContentTouches: Bool) -> Self {
        self.canCancelContentTouches = canCancelContentTouches
        return self
    }
}
