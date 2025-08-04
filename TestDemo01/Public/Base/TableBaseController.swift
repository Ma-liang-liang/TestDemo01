//
//  TableBaseController.swift
//  sufinc_global_account_module
//
//  Created by sunshine on 2023/11/6.
//

import UIKit

class SKTableBaseController: SKBaseController {
    
    var tableStyle: UITableView.Style { .plain }
    
    override func makeUI() {
        
        view.addSubview(tableView)
        if needNavBar {
            tableView.snp.makeConstraints { make in
                make.top.equalTo(navBar.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        tableView.isHidden = false
    }
    
    @objc
    func onAction(_ sender: UIButton) {
        
    }
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero,style: tableStyle)
            .cg_showsVerticalScrollIndicator(false)
            .cg_dataSource(self)
            .cg_delegate(self)
            .cg_tableFooterView(UIView())
            .cg_tableFooterView(UIView())
            .cg_estimatedSectionHeaderHeight(0)
            .cg_sectionHeaderHeight(0)
            .cg_estimatedRowHeight(60.px)
            .cg_rowHeight(UITableView.automaticDimension)
            .cg_separatorStyle(.none)
            .cg_sectionHeaderTopPadding(0)
            .cg_setBackgroundColor(.clear)
            .cg_register(UITableViewCell.self)
            .cg_contentInset(bottom: UIScreen.kTabbarHeight)
        return table
    }()
    
    lazy var action1Button = {
        let button = UIButton()
            .cg_addTarget(self, action: #selector(onAction))
        return button
    }()
    
    
    lazy var action2Button = {
        let button = UIButton()
            .cg_addTarget(self, action: #selector(onAction))
        button.backgroundColor = .white
        return button
    }()
    
}

extension SKTableBaseController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withClass: UITableViewCell.self)
    }
    
}
