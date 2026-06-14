import UIKit
import SwiftUI

class SwiftUIDemoListController: SKBaseController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let demos: [(name: String, view: AnyView)] = [
        ("复杂UI布局", AnyView(ComplexUIDemo())),
        ("CGKit导航", AnyView(CGKitContentView())),
        ("聊天页面", AnyView(ALChatPage())),
        ("图片商店", AnyView(ImageShopPage())),
        ("输入框组件", AnyView(InputPage())),
        ("充值页面", AnyView(ALTopUpPage())),
        ("Sheet弹出", AnyView(ALSheetPage(onDismiss: {}, onPinkAreaTap: {}))),
        ("滚动卡片", AnyView(ALScrollCardView())),
        ("UIKit+SwiftUI Collection", AnyView(UIKitCollectionPageWrapper())),
        ("列表页面", AnyView(HomeListPage())),
        ("自定义下拉刷新", AnyView(GridContentView())),
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

extension SwiftUIDemoListController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "SwiftUI Demo"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = demos[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let demo = demos[indexPath.row]
        let wrappedView = CGBackButtonWrapper {
            demo.view
        }
        let vc = UIHostingController(rootView: wrappedView)
        CGNavigationManager.shared.push(vc, stackId: .swiftUI)
    }
}
