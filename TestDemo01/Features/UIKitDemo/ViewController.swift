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
        
        if let nav = navigationController {
            nav.setNavigationBarHidden(true, animated: false)
            nav.stackId = .demo
            CGNavigationManager.shared.setNavigationStack(nav, forId: .demo)
            CGNavigationManager.shared.switchToStack(id: .demo)
        }
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
            CGNavigationManager.shared.push(vc)
        case .second:
            let vc = SecondController()
            CGNavigationManager.shared.push(vc)
        case .third:
            let vc = ThirdController()
            CGNavigationManager.shared.push(vc)
        case .web1:
            let vc = WebViewController(url: "https://www.baidu.com/")
            CGNavigationManager.shared.push(vc)
        case .swiftui_one:
            let vc = UIHostingController(rootView: ComplexUIDemo())
            CGNavigationManager.shared.push(vc)
        case .tabScroll:
            let vc = TabScrollViewController()
            CGNavigationManager.shared.push(vc)
        case .videoDemo:
            let vc = VideoDemoController()
            CGNavigationManager.shared.push(vc)
        case .iconFont:
            let vc = IconFontController()
            CGNavigationManager.shared.push(vc)
        case .theme:
            let vc = SKThemeSetController()
            CGNavigationManager.shared.push(vc)
        case .liveBroadcast:
            let vc = ALLiveBroadcastController()
            CGNavigationManager.shared.push(vc)
        case .homeSwiftUI:
            let vc = UIHostingController(rootView: HomeListPage())
            CGNavigationManager.shared.push(vc)
        case .pagingTable:
            let vc = PagingTableViewController()
            CGNavigationManager.shared.push(vc)
        case .collection:
            let vc = ALCollectionController()
            CGNavigationManager.shared.push(vc)
        case .liveGift:
            let vc = ALLiveGiftController()
            CGNavigationManager.shared.push(vc)
        case .jxSegment:
            let vc = JXSegmentController()
            CGNavigationManager.shared.push(vc)
        case .imageShop:
            let vc = UIHostingController(rootView: ImageShopPage())
            CGNavigationManager.shared.push(vc)
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
    
    case theme = "SKThemeSetController"
    
    case liveBroadcast = "ALLiveBroadcastController"
    
    case homeSwiftUI = "HomeListPage"
    
    case pagingTable = "PagingTableViewController"
    
    case collection = "ALCollectionController"
    
    case liveGift = "ALLiveViewController"
    
    case jxSegment = "JXSegmentController"
    
    case imageShop = "ImageShopPage"
}
