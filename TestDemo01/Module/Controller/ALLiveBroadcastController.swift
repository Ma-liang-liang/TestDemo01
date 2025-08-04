//
//  ALLiveBroadcastController.swift
//  TestDemo
//
//  Created by as on 2025/6/14.
//

import UIKit
import SnapKit
import AgoraRtcKit

class ALLiveBroadcastController: SKBaseController {
    
    let liveManager = LiveStreamManager(appId: agoraAPPID, token: agoraToken)

    override func viewDidLoad() {
        super.viewDidLoad()


        makeUI()
        
    }
    
    override func makeUI() {
        
        navBar.titleLabel.text = "直播"
        
        view.addSubviews {
            leftView
            rightView
            joinChannelButton
        }
        
        leftView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom).offset(80)
            make.height.equalTo(300)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        
        rightView.snp.makeConstraints { make in
            make.leading.equalTo(leftView.snp.trailing)
            make.top.bottom.equalTo(leftView)
            make.trailing.equalToSuperview()
        }
        
        joinChannelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.top.equalTo(leftView.snp.bottom).offset(60)
            make.width.equalTo(80)
            make.height.equalTo(36)
        }
        
        
        liveManager.delegate = self
        liveManager.setupAgoraEngine()
       
        let room = LiveRoom(roomId: "123", ownerId: "0000", ownerName: "哈哈哈哈", ownerAvatar: "")

        liveManager.createLiveRoom(room: room, localVideoView: leftView) { isSuccess, error in
            
            if isSuccess {
                print("create success")
            } else {
                print("error = \(error?.localizedDescription)")
            }
        }

    }
    
    
    @objc
    func onAction(sender: UIButton) {
        
        if sender == joinChannelButton {
            
            let room = LiveRoom(roomId: "123", ownerId: "1111", ownerName: "嘻嘻嘻嘻", ownerAvatar: "1111")

//            liveManager.joinLiveRoom(room: room, remoteVideoView: rightView) { isSuccess, error in
//                
//                if isSuccess {
//                    print("join success")
//                } else {
//                    print("error = \(error?.localizedDescription)")
//                }
//            }
            
            liveManager.startPKConnection(targetRoom: room, remoteVideoView: rightView) {  isSuccess, error in
                
                if isSuccess {
                    print("start pk success")
                } else {
                    print("error = \(error?.localizedDescription)")
                }
            }
            
//            liveManager.requestCoHost(localVideoView: rightView) { isSuccess, error in
//                if isSuccess {
//                    print("requestCoHost success")
//                } else {
//                    print("error = \(error?.localizedDescription)")
//                }
//            }
        }
    }

    
    private lazy var leftView = UIView()
        .cg_setBackgroundColor(.systemPink.withAlphaComponent(0.5))
    
    private lazy var rightView = UIView()
        .cg_setBackgroundColor(.green.withAlphaComponent(0.5))
    
    private lazy var joinChannelButton: UIButton = {
        let button = UIButton()
            .cg_setTitle("加入")
            .cg_setTitleColor(.systemPink)
            .cg_addTarget(self, action: #selector(onAction(sender:)))
            .cg_setBackgroundColor(.cyan)
        
        button.addRectCorner(corner: .allCorners, radius: 6)
        return button
    }()
   
}

extension ALLiveBroadcastController: LiveStreamManagerDelegate {
  
    func liveStreamManager(_ manager: LiveStreamManager, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didLeaveChannelWithStats stats: AgoraChannelStats) {
        
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didJoinedOfUid uid: UInt, elapsed: Int) {
        
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, interactionStatusChanged info: InteractionInfo) {
        
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, pkStatusChanged isConnected: Bool, targetRoom: LiveRoom?) {
        
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didOccurError error: AgoraErrorCode) {
        
    }
    
    
    
}
