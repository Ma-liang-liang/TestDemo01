import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupAppearance()
        setupViewControllers()
        registerNavigationStacks()
    }

    private func setupAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .systemBackground
    }

    private func setupViewControllers() {
        let uikitDemoNav = createNavStack(
            root: UIKitDemoListController(),
            stackId: .uikit,
            title: "UIKit",
            imageName: "square.grid.2x2"
        )

        let swiftUIDemoNav = createNavStack(
            root: SwiftUIDemoListController(),
            stackId: .swiftUI,
            title: "SwiftUI",
            imageName: "swift"
        )

        let settingsNav = createNavStack(
            root: SettingsController(),
            stackId: .settings,
            title: "设置",
            imageName: "gearshape"
        )

        viewControllers = [uikitDemoNav, swiftUIDemoNav, settingsNav]
    }

    private func createNavStack(
        root: UIViewController,
        stackId: CGStackIdentifier,
        title: String,
        imageName: String
    ) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.isHidden = true
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: nil
        )
        nav.stackId = stackId
        return nav
    }

    private func registerNavigationStacks() {
        guard let viewControllers = viewControllers else { return }
        for case let nav as UINavigationController in viewControllers {
            if let stackId = nav.stackId {
                CGNavigationManager.shared.setNavigationStack(nav, forId: stackId)
            }
        }
        CGNavigationManager.shared.switchToStack(id: .uikit)
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let nav = viewController as? UINavigationController,
              let stackId = nav.stackId else { return }
        CGNavigationManager.shared.switchToStack(id: stackId)
    }
}
