import UIKit

class UIKitDemoListController: SKBaseController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let sections: [(title: String, items: [(name: String, vcFactory: () -> UIViewController)])] = [
        ("动画/动效", [
            ("动画/YYImage/YYText", { SecondController() }),
            ("Flex Tags标签流", { NTFlexTagsController() }),
        ]),
        ("UI组件", [
            ("Tab滚动", { TabScrollViewController() }),
            ("分页滚动", { PagingTableViewController() }),
            ("UICollectionView", { ALCollectionController() }),
            ("JXSegment分段", { JXSegmentController() }),
            ("IconFont图标", { IconFontController() }),
        ]),
        ("媒体", [
            ("视频播放", { VideoDemoController() }),
            ("直播", { ALLiveBroadcastController() }),
            ("礼物跑马灯", { ALLiveGiftController() }),
        ]),
        ("网络/API", [
            ("API网络请求", { ThirdController() }),
            ("WebView", { WebViewController(url: "https://www.baidu.com/") }),
        ]),
        ("硬件通信", [
            ("蓝牙通信优化", { BluetoothDemoController() }),
            ("MQTT 通信", { MQTTDemoController() }),
        ]),
        ("其他", [
            ("HomeController", { HomeController() }),
            ("主题切换", { SKThemeSetController() }),
        ]),
        ("算法练习", [
            ("算法题库（每周两题）", { AlgorithmListController() }),
        ]),
    ]

    override var needNavBar: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension UIKitDemoListController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        let vc = item.vcFactory()
        CGNavigationManager.shared.push(vc, stackId: .uikit)
    }
}
