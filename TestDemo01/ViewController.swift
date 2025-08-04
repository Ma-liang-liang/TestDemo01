//
//  ViewController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/2/18.
//

import UIKit
import SwiftUI

class ViewController: SKBaseController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(cellWithClass: UITableViewCell.self)
        
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        tableView.backgroundColor = .random.lighten()
        
        self.navBar.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("navBar.height = \(navBar.height)")
        view.layoutIfNeeded()
    }
     
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        PageType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self)
        let page = PageType.allCases[indexPath.row]
        cell.textLabel?.text = page.rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let page = PageType.allCases[indexPath.row]

        
        switch page {
        case .home:
            let vc = HomeController()
            navigationController?.pushViewController(vc, animated: true)
        case .second:
            let vc = SecondController()
            navigationController?.pushViewController(vc, animated: true)
        case .third:
            let vc = ThirdController()
            navigationController?.pushViewController(vc, animated: true)
        case .web1:
            let vc = WebViewController(url: "https://www.baidu.com/")
            navigationController?.pushViewController(vc, animated: true)
        case .swiftui_one:
            let vc = UIHostingController(rootView: ComplexUIDemo())
            navigationController?.pushViewController(vc, animated: true)
        case .tabScroll:
            let vc = TabScrollViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .videoDemo:
            let vc = VideoDemoController()
            navigationController?.pushViewController(vc, animated: true)
        case .iconFont:
            let vc = IconFontController()
            navigationController?.pushViewController(vc, animated: true)
        case .storeBox:
            let vc = StoreBoxController()
            navigationController?.pushViewController(vc, animated: true)
        case .theme:
            let vc = SKThemeSetController()
            navigationController?.pushViewController(vc, animated: true)
        case .liveBroadcast:
            let vc = ALLiveBroadcastController()
            navigationController?.pushViewController(vc, animated: true)
        case .homeSwiftUI:
            let vc = UIHostingController(rootView: HomeListPage())
            navigationController?.pushViewController(vc, animated: true)
        case .pagingTable:
            let vc = PagingTableViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .collection:
            let vc = ALCollectionController()
            navigationController?.pushViewController(vc, animated: true)
        case .liveGift:
            let vc = ALLiveGiftController()
            navigationController?.pushViewController(vc, animated: true)
            
            
        }
    }
    
    
}

enum PageType: String, CaseIterable {
    
    case home = "HomeController"
    
    case second = "SecondController"
    
    case third = "ThirdController"
    
    case web1 = "WebViewController"
    
    case swiftui_one = "ComplexUIDemo"
    
    case tabScroll = "TabScrollViewController"
    
    case videoDemo = "VideoDemoController"
    
    case iconFont = "IconFontController"
    
    case storeBox = "StoreBoxController"
    
    case theme = "SKThemeSetController"
    
    case liveBroadcast = "ALLiveBroadcastController"
    
    case homeSwiftUI = "HomeListPage"
    
    case pagingTable = "PagingTableViewController"
    
    case collection = "ALCollectionController"
    
    case liveGift = "ALLiveViewController"
}
