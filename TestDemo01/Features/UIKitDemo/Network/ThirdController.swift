//
//  ThirdController.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/3/11.
//

import UIKit
import Combine
import CombineCocoa

class ThirdController: SKBaseController {
    
    private let viewModel = ThirdViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubviews {
            pushBtn
        }
        
        pushBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(44)
            make.top.equalToSuperview().offset(180)
            make.height.equalTo(40)
        }
             
//        test1()
        
        SKAPIConfiguration.addConfig()
        
        test_request3()
      
        test_request4()

    }
    
    
    
    @objc func onClick(_ sender: UIButton) {
        test3()
    }
    
    lazy var pushBtn: UIButton = {
        let btn = UIButton()
            .cg_setTitle("push next")
            .cg_setTitleColor(.red)
            .cg_setBackgroundColor(.white)
            .cg_addTarget(self, action: #selector(onClick))
        return btn
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
    }
    
    private func test_request1() {
        Task {
            
            do {
                let resuts = try await SKApiService.sendRequest(apiProtocol: MockApi.postPosts)
                
                print("resuts = \(resuts)")
            } catch {
                let error = error as NSError
                print("error = \(error.domain)")
            }
        }
    }
    
    private func test_request2() {
        Task {
            do {
                let resuts = try await SKApiService.sendArrayRequest(apiProtocol: ReqResApi.getUsers(page: 2), modelType: MockUserModel.self)                 
                print("resuts = \(resuts)")
            } catch {
                let error = error as NSError
                print("error = \(error.domain)")
            }
        }
    }
    
    private func test_request3() {
        Task {
            do {
                let resuts = try await SKApiService.sendObjectRequest(apiProtocol: ReqResApi.getSingleUser(id: 2), modelType: MockUserModel.self)
                print("resuts = \(String(describing: resuts))")
            } catch {
                let error = error as NSError
                print("error = \(error.domain)")
            }
        }
    }
    
    private func test_request4() {
        Task {
            do {
                let resuts = try await SKApiService.sendObjectRequest(apiProtocol: ReqResApi.createUser(name: "哈哈哈", job: "CEO"), modelType: MockUserModel.self)
                print("resuts = \(String(describing: resuts))")
            } catch {
                let error = error as NSError
                print("error = \(error.domain)")
            }
        }
    }

    
    func test1() {
        // 订阅数组变化
        viewModel.$items
            .sink { [weak self] items in
                print("数组变化后的新值：\(items)")
                // 更新 UI（如刷新列表）
            }
            .store(in: &cancelables)
        // 模拟修改数组
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.viewModel.items.append("元素1")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.viewModel.items.append("元素2")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.viewModel.items.removeAll()
        }
    }
    
    func test2() {
        let queue = DispatchQueue(label: "com.example.serialQueue") // 局部变量
        
        queue.async {
            print("任务1开始")
            sleep(1)
            print("任务1结束")
            sleep(1)
        }
        
        queue.async {
            print("任务2开始")
            sleep(1)
            print("任务2结束")
            sleep(1)
        }
        
        queue.async {
            print("任务3开始 == \(type(of: self))")
        }
    }
    
    func test3() {
        
        let url1 = "https://f7.baidu.com/it/u=500783997,1623136713&fm=222&app=108&f=PNG@s_0,w_800,h_1000,q_80,f_auto"
        let url2 = "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic%2Fd0%2F72%2F0d%2Fd0720db0956708d6a9f0b387597be31f.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=1764652e87980463227cba3c6fb6fe25"
        let url3 = "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic%2F75%2Fdc%2F50%2F75dc50577d3d3d2bd5fd8db728e7bf77.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=d216c4dae3c9d5f6fee735ec7fbe8771"
        let url4 = "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fup.enterdesk.com%2Fedpic_source%2F3d%2F42%2F3e%2F3d423e3cb05d7edc35c38e3173af2a0d.jpg&refer=http%3A%2F%2Fup.enterdesk.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1674462223&t=5ccb00c0328b8ba0d522ac2e17e3a7bd"
        
        let resources = [
            MediaResource(url: url1, type: .image, thumbnail: UIImage(named: "卡通鸟1")),
            MediaResource(url: url2, type: .image, thumbnail: UIImage(named: "卡通鸟1")),
            MediaResource(url: url3, type: .image, thumbnail: UIImage(named: "卡通鸟1")),
            MediaResource(url: url4, type: .image, thumbnail: UIImage(named: "卡通鸟1"))

//            MediaResource(url: videoURL, type: .video, thumbnail: thumbnailImage),
//            MediaResource(url: gifURL, type: .gif)
        ]

        let browser = MediaBrowserViewController(resources: resources, currentIndex: 0)
        present(browser, animated: true)
    }

    
}

