//
//  UITableView+Chain.swift
//  FDCache
//
//  Created by sunshine on 2023/6/11.
//

import UIKit

public
extension UITableView {
  
    @discardableResult
    func cg_register<Cell: UITableViewCell>(_ cellClass: Cell.Type) -> Self {
        register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        return self
    }
    
    @discardableResult
    func cg_registerHeaderFooterView<View: UITableViewHeaderFooterView>(_ viewClass: View.Type) -> Self {
        register(viewClass, forHeaderFooterViewReuseIdentifier: String(describing: viewClass))
        return self
    }

    @discardableResult
    func cg_dataSource(_ dataSource: UITableViewDataSource?) -> Self {
        self.dataSource = dataSource
        return self
    }

    @discardableResult
    func cg_delegate(_ delegate: UITableViewDelegate?) -> Self {
        self.delegate = delegate
        return self
    }

    @discardableResult
    func cg_rowHeight(_ rowHeight: CGFloat) -> Self {
        self.rowHeight = rowHeight
        return self
    }
    
    @discardableResult
    func cg_separatorStyle(_ separatorStyle: UITableViewCell.SeparatorStyle) -> Self {
        self.separatorStyle = separatorStyle
        return self
    }

    @discardableResult
    func cg_separatorInset(_ separatorInset: UIEdgeInsets) -> Self {
        self.separatorInset = separatorInset
        return self
    }
    
    
    @discardableResult
    func cg_sectionHeaderTopPadding(_ sectionHeaderTopPadding: CGFloat) -> Self {
        if #available(iOS 15.0, *) {
            self.sectionHeaderTopPadding = sectionHeaderTopPadding
        }
        return self
    }
    
    @discardableResult
    func cg_contentInsetAdjustmentBehavior(_ contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior) -> Self {
        self.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        return self
    }

    @discardableResult
    func cg_allowsSelection(_ allowsSelection: Bool) -> Self {
        self.allowsSelection = allowsSelection
        return self
    }

    @discardableResult
    func cg_allowsMultipleSelection(_ allowsMultipleSelection: Bool) -> Self {
        self.allowsMultipleSelection = allowsMultipleSelection
        return self
    }

    @discardableResult
    func cg_backgroundView(_ backgroundView: UIView?) -> Self {
        self.backgroundView = backgroundView
        return self
    }

    @discardableResult
    func cg_sectionHeaderHeight(_ sectionHeaderHeight: CGFloat) -> Self {
        self.sectionHeaderHeight = sectionHeaderHeight
        return self
    }

    @discardableResult
    func cg_sectionFooterHeight(_ sectionFooterHeight: CGFloat) -> Self {
        self.sectionFooterHeight = sectionFooterHeight
        return self
    }

    @discardableResult
    func cg_estimatedRowHeight(_ estimatedRowHeight: CGFloat) -> Self {
        self.estimatedRowHeight = estimatedRowHeight
        return self
    }

    @discardableResult
    func cg_estimatedSectionHeaderHeight(_ estimatedSectionHeaderHeight: CGFloat) -> Self {
        self.estimatedSectionHeaderHeight = estimatedSectionHeaderHeight
        return self
    }

    @discardableResult
    func cg_estimatedSectionFooterHeight(_ estimatedSectionFooterHeight: CGFloat) -> Self {
        self.estimatedSectionFooterHeight = estimatedSectionFooterHeight
        return self
    }

    @discardableResult
    func cg_tableHeaderView(_ tableHeaderView: UIView?) -> Self {
        self.tableHeaderView = tableHeaderView
        return self
    }

    @discardableResult
    func cg_tableFooterView(_ tableFooterView: UIView?) -> Self {
        self.tableFooterView = tableFooterView
        return self
    }
    
}
