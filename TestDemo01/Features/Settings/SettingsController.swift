import UIKit

class SettingsController: SKBaseController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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

extension SettingsController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "外观" : "关于"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if indexPath.section == 0 {
            cell.textLabel?.text = "深色模式"
            let toggle = UISwitch()
            toggle.isOn = UITraitCollection.current.userInterfaceStyle == .dark
            toggle.addTarget(self, action: #selector(themeToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        } else {
            cell.textLabel?.text = "TestDemo v1.0"
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }

        return cell
    }

    @objc private func themeToggleChanged(_ sender: UISwitch) {
        if sender.isOn {
            ALThemeManager.shared.setAppTheme(.dark)
        } else {
            ALThemeManager.shared.setAppTheme(.light)
        }
    }
}


func test1(s: String) -> Bool {
    
    var stack = [Character]()
    let dict: [Character: Character] = ["}": "{", "]": "[", ")": "("]
    
    for char in s {
        
        if let left = dict[char] {
            guard let last = stack.popLast(), last == left else {
                return false
            }
            
        } else {
            stack.append(char)
        }
        
    }
    
    return stack.isEmpty
}
