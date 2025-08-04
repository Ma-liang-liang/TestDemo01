//
//  LiveStreamManager.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/6/8.
//

import UIKit
import AgoraRtcKit
import Foundation


let agoraAPPID = "5ebd265f8146475ebe572bf9b1145551"
let agoraToken = "007eJxTYEg4tTy8uuD1/rnHbq3Qf2PM++TK9qjL0T9Xev69fcxU2ClHgcE0NSnFyMw0zcLQxMzEHMhLNTU3SkqzTDI0NDE1NTV8dtknoyGQkeHr9BpmRgYIBPGZGQyNjBkYACvcIdY="

// MARK: - 直播间信息模型
struct LiveRoom {
    let roomId: String
    let ownerId: String
    let ownerName: String
    let ownerAvatar: String
    var isLive: Bool = false
}

// MARK: - 连麦信息模型
struct InteractionInfo {
    let userId: String
    let userName: String
    let userAvatar: String
    let roomId: String
    var isConnected: Bool = false
}

// MARK: - 直播管理器代理协议
protocol LiveStreamManagerDelegate: AnyObject {
    /// 用户加入频道成功
    func liveStreamManager(_ manager: LiveStreamManager, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int)
    
    /// 用户离开频道
    func liveStreamManager(_ manager: LiveStreamManager, didLeaveChannelWithStats stats: AgoraChannelStats)
    
    /// 远端用户加入
    func liveStreamManager(_ manager: LiveStreamManager, didJoinedOfUid uid: UInt, elapsed: Int)
    
    /// 远端用户离开
    func liveStreamManager(_ manager: LiveStreamManager, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason)
    
    /// 连麦状态变化
    func liveStreamManager(_ manager: LiveStreamManager, interactionStatusChanged info: InteractionInfo)
    
    /// PK连麦状态变化
    func liveStreamManager(_ manager: LiveStreamManager, pkStatusChanged isConnected: Bool, targetRoom: LiveRoom?)
    
    /// 发生错误
    func liveStreamManager(_ manager: LiveStreamManager, didOccurError error: AgoraErrorCode)
}

// MARK: - 直播管理器主类
class LiveStreamManager: NSObject {
    
    // MARK: - Properties
    weak var delegate: LiveStreamManagerDelegate?
    
    private var agoraKit: AgoraRtcEngineKit?
    private var currentRoom: LiveRoom?
    private var currentRole: AgoraClientRole = .audience
    private var exConnectionMap: [String: AgoraRtcConnection] = [:]
    private var delegateMap: [String: AgoraRtcEngineDelegate] = [:]
    private var isLocalVideoEnabled = false
    private var isLocalAudioEnabled = false
    private var isEngineInitialized = false
    
    // 配置信息
    private let appId: String
    private let token: String?
    
    // MARK: - 初始化
    init(appId: String, token: String? = nil) {
        self.appId = appId
        self.token = token
        super.init()
        
        // 延迟初始化，在实际使用时再初始化引擎
    }
    
    deinit {
        destroy()
    }
    
    // MARK: - Engine Setup
    @discardableResult
    func setupAgoraEngine() -> Bool {
        guard !isEngineInitialized else { return true }
        
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.areaCode = .global
        config.channelProfile = .liveBroadcasting
        
        do {
            agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
            
            guard let engine = agoraKit else {
                print("Failed to create Agora RTC Engine")
                return false
            }
            
            // 基础配置
            engine.setDefaultAudioRouteToSpeakerphone(true)
            engine.enableAudio()
            engine.enableVideo()
            
            // 设置视频编码配置
            let videoConfig = AgoraVideoEncoderConfiguration(
                size: AgoraVideoDimension1280x720,
                frameRate: .fps15,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: .fixedPortrait,
                mirrorMode: .auto
            )
            engine.setVideoEncoderConfiguration(videoConfig)
            
            isEngineInitialized = true
            return true
            
        } catch {
            print("Failed to initialize Agora RTC Engine: \(error)")
            return false
        }
    }
    
    // MARK: - 1. 创建直播间
    func createLiveRoom(room: LiveRoom, localVideoView: UIView, completion: @escaping (Bool, Error?) -> Void) {
        // 确保引擎已初始化
        guard setupAgoraEngine(), let engine = agoraKit else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "RTC引擎初始化失败"]))
            return
        }
        
        currentRoom = room
        currentRole = .broadcaster
        
        // 设置本地视频
        setupLocalVideo(uid: UInt(room.ownerId) ?? 0, canvasView: localVideoView)
        
        // 加入频道
        joinChannel(channelId: room.roomId, uid: UInt(room.ownerId) ?? 0, role: .broadcaster) { [weak self] success, error in
            if success {
                self?.isLocalVideoEnabled = true
                self?.isLocalAudioEnabled = true
            }
            completion(success, error)
        }
    }
    
    // MARK: - 2. 进入直播间
    func joinLiveRoom(room: LiveRoom, remoteVideoView: UIView, completion: @escaping (Bool, Error?) -> Void) {
        // 确保引擎已初始化
        guard setupAgoraEngine(), let engine = agoraKit else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "RTC引擎初始化失败"]))
            return
        }
        
        currentRoom = room
        currentRole = .audience
        
        // 加入频道作为观众
        joinChannel(channelId: room.roomId, uid: UInt(room.ownerId) ?? 0, role: .audience) { [weak self] success, error in
            if success {
                // 设置远端视频（主播视频）
                self?.setupRemoteVideo(channelId: room.roomId, uid: UInt(room.ownerId) ?? 0, canvasView: remoteVideoView)
            }
            completion(success, error)
        }
    }
    
    // MARK: - 3. 主播PK连麦
    func startPKConnection(targetRoom: LiveRoom, remoteVideoView: UIView, completion: @escaping (Bool, Error?) -> Void) {
        guard let currentRoom = currentRoom else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前房间信息为空"]))
            return
        }
        
        // 加入对方频道
        joinChannelEx(currentChannelId: currentRoom.roomId,
                     targetChannelId: targetRoom.roomId,
                     ownerId: UInt(targetRoom.ownerId) ?? 0,
                     role: currentRole) { [weak self] success, error in
            if success {
                // 设置对方主播的视频
                self?.setupRemoteVideo(channelId: targetRoom.roomId,
                                     uid: UInt(targetRoom.ownerId) ?? 0,
                                     canvasView: remoteVideoView)
                
                // 通知代理PK连麦状态变化
                self?.delegate?.liveStreamManager(self ?? LiveStreamManager(appId: ""), pkStatusChanged: true, targetRoom: targetRoom)
            }
            completion(success, error)
        }
    }
    
    func stopPKConnection(targetRoom: LiveRoom) {
        guard let currentRoom = currentRoom else { return }
        
        leaveChannelEx(roomId: currentRoom.roomId, channelId: targetRoom.roomId)
        delegate?.liveStreamManager(self, pkStatusChanged: false, targetRoom: nil)
    }
    
    // MARK: - 4. 观众连麦
    func requestCoHost(localVideoView: UIView, completion: @escaping (Bool, Error?) -> Void) {
        guard let room = currentRoom, currentRole == .audience else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前状态不支持连麦"]))
            return
        }
        
        // 切换角色为主播
        switchRole(role: .broadcaster, channelId: room.roomId, uid: UInt(room.ownerId) ?? 0, canvasView: localVideoView) { [weak self] success, error in
            if success {
                self?.currentRole = .broadcaster
                self?.isLocalVideoEnabled = true
                self?.isLocalAudioEnabled = true
                
                let interactionInfo = InteractionInfo(
                    userId: room.ownerId,
                    userName: room.ownerName,
                    userAvatar: room.ownerAvatar,
                    roomId: room.roomId,
                    isConnected: true
                )
                self?.delegate?.liveStreamManager(self ?? LiveStreamManager(appId: ""), interactionStatusChanged: interactionInfo)
            }
            completion(success, error)
        }
    }
    
    func stopCoHost(completion: @escaping (Bool, Error?) -> Void) {
        guard let room = currentRoom else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前房间信息为空"]))
            return
        }
        
        // 切换回观众角色
        switchRole(role: .audience, channelId: room.roomId, uid: nil, canvasView: nil) { [weak self] success, error in
            if success {
                self?.currentRole = .audience
                self?.isLocalVideoEnabled = false
                self?.isLocalAudioEnabled = false
                self?.agoraKit?.stopPreview()
                
                let interactionInfo = InteractionInfo(
                    userId: room.ownerId,
                    userName: room.ownerName,
                    userAvatar: room.ownerAvatar,
                    roomId: room.roomId,
                    isConnected: false
                )
                self?.delegate?.liveStreamManager(self ?? LiveStreamManager(appId: ""), interactionStatusChanged: interactionInfo)
            }
            completion(success, error)
        }
    }
    
    // MARK: - 5. 音视频控制
    func muteLocalAudio(_ mute: Bool) {
        guard let engine = agoraKit else { return }
        engine.muteLocalAudioStream(mute)
        isLocalAudioEnabled = !mute
    }
    
    func muteLocalVideo(_ mute: Bool) {
        guard let engine = agoraKit else { return }
        engine.muteLocalVideoStream(mute)
        isLocalVideoEnabled = !mute
        if mute {
            engine.stopPreview()
        } else {
            engine.startPreview()
        }
    }
    
    func switchCamera() {
        guard let engine = agoraKit else { return }
        engine.switchCamera()
    }
    
    // MARK: - 6. 离开直播间
    func leaveLiveRoom(completion: @escaping (Bool, Error?) -> Void) {
        guard let room = currentRoom, let engine = agoraKit else {
            completion(true, nil)
            return
        }
        
        // 停止预览
        engine.stopPreview()
        
        // 离开频道
        engine.leaveChannel { [weak self] stats in
            self?.currentRoom = nil
            self?.currentRole = .audience
            self?.isLocalVideoEnabled = false
            self?.isLocalAudioEnabled = false
            completion(true, nil)
        }
        
        // 清理连接映射
        exConnectionMap.removeAll()
        delegateMap.removeAll()
    }
    
    // MARK: - 7. 销毁资源
    func destroy() {
        if isEngineInitialized {
            AgoraRtcEngineKit.destroy()
            agoraKit = nil
            isEngineInitialized = false
        }
    }
}

// MARK: - Private Methods
private extension LiveStreamManager {
    
    func joinChannel(channelId: String, uid: UInt, role: AgoraClientRole, completion: @escaping (Bool, Error?) -> Void) {
        guard let engine = agoraKit else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "RTC引擎未初始化"]))
            return
        }
        
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.clientRoleType = role
        mediaOptions.autoSubscribeAudio = true
        mediaOptions.autoSubscribeVideo = true
        
        if role == .audience {
            mediaOptions.audienceLatencyLevel = .lowLatency
        }
        
        let result = engine.joinChannel(byToken: token, channelId: channelId, uid: uid, mediaOptions: mediaOptions) { channelName, uid, elapsed in
            completion(true, nil)
        }
        
        if result != 0 {
            completion(false, NSError(domain: "AgoraError", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "加入频道失败"]))
        }
    }
    
    func joinChannelEx(currentChannelId: String, targetChannelId: String, ownerId: UInt, role: AgoraClientRole, completion: @escaping (Bool, Error?) -> Void) {
        guard let engine = agoraKit else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "RTC引擎未初始化"]))
            return
        }
        
        if exConnectionMap[targetChannelId] != nil {
            completion(true, nil)
            return
        }
        
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.autoSubscribeAudio = role == .broadcaster
        mediaOptions.autoSubscribeVideo = role == .broadcaster
        mediaOptions.clientRoleType = role
        
        if role == .audience {
            mediaOptions.audienceLatencyLevel = .lowLatency
        }
        
        let connection = AgoraRtcConnection()
        connection.channelId = targetChannelId
        connection.localUid = ownerId
        
        let result = engine.joinChannelEx(byToken: token, connection: connection, delegate: self, mediaOptions: mediaOptions) { channelName, uid, elapsed in
            completion(true, nil)
        }
        
        if result == 0 {
            engine.updateChannelEx(with: mediaOptions, connection: connection)
            exConnectionMap[targetChannelId] = connection
        } else {
            completion(false, NSError(domain: "AgoraError", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "加入频道Ex失败"]))
        }
    }
    
    func leaveChannelEx(roomId: String, channelId: String) {
        guard let engine = agoraKit, let connection = exConnectionMap[channelId] else { return }
        engine.leaveChannelEx(connection)
        exConnectionMap[channelId] = nil
    }
    
    func setupLocalVideo(uid: UInt, canvasView: UIView) {
        guard let engine = agoraKit else { return }
        
        let canvas = AgoraRtcVideoCanvas()
        canvas.view = canvasView
        canvas.uid = uid
        canvas.mirrorMode = .disabled
        canvas.renderMode = .hidden
        
        engine.setupLocalVideo(canvas)
        engine.startPreview()
    }
    
    func setupRemoteVideo(channelId: String, uid: UInt, canvasView: UIView) {
        guard let engine = agoraKit else { return }
        
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = canvasView
        canvas.renderMode = .hidden
        
        if let connection = exConnectionMap[channelId] {
            engine.setupRemoteVideoEx(canvas, connection: connection)
        } else {
            engine.setupRemoteVideo(canvas)
        }
    }
    
    func switchRole(role: AgoraClientRole, channelId: String, uid: UInt?, canvasView: UIView?, completion: @escaping (Bool, Error?) -> Void) {
        guard let engine = agoraKit else {
            completion(false, NSError(domain: "LiveStreamManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "RTC引擎未初始化"]))
            return
        }
        
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.clientRoleType = role
        mediaOptions.autoSubscribeAudio = true
        mediaOptions.autoSubscribeVideo = true
        
        if role == .audience {
            mediaOptions.audienceLatencyLevel = .lowLatency
        }
        
        updateChannelEx(channelId: channelId, options: mediaOptions)
        
        if let uid = uid, let canvasView = canvasView {
            if role == .broadcaster {
                setupLocalVideo(uid: uid, canvasView: canvasView)
            } else {
                setupRemoteVideo(channelId: channelId, uid: uid, canvasView: canvasView)
            }
        }
        
        completion(true, nil)
    }
    
    func updateChannelEx(channelId: String, options: AgoraRtcChannelMediaOptions) {
        guard let engine = agoraKit else { return }
        
        if let connection = exConnectionMap[channelId] {
            engine.updateChannelEx(with: options, connection: connection)
        }
    }
}

// MARK: - AgoraRtcEngineDelegate
extension LiveStreamManager: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        delegate?.liveStreamManager(self, didJoinChannel: channel, withUid: uid, elapsed: elapsed)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        
        delegate?.liveStreamManager(self, didLeaveChannelWithStats: stats)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        delegate?.liveStreamManager(self, didJoinedOfUid: uid, elapsed: elapsed)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        delegate?.liveStreamManager(self, didOfflineOfUid: uid, reason: reason)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        delegate?.liveStreamManager(self, didOccurError: errorCode)
    }
}

// MARK: - 使用示例
/*
class ViewController: UIViewController {
    private var liveManager: LiveStreamManager!
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化直播管理器
        liveManager = LiveStreamManager(appId: "your_app_id", token: "your_token")
        liveManager.delegate = self
    }
    
    // 创建直播间
    @IBAction func createRoom() {
        let room = LiveRoom(roomId: "room_001", ownerId: "user_001", ownerName: "主播", ownerAvatar: "avatar.jpg")
        liveManager.createLiveRoom(room: room, localVideoView: localVideoView) { success, error in
            if success {
                print("创建直播间成功")
            } else {
                print("创建直播间失败: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    // 加入直播间
    @IBAction func joinRoom() {
        let room = LiveRoom(roomId: "room_001", ownerId: "user_001", ownerName: "主播", ownerAvatar: "avatar.jpg")
        liveManager.joinLiveRoom(room: room, remoteVideoView: remoteVideoView) { success, error in
            if success {
                print("加入直播间成功")
            } else {
                print("加入直播间失败: \(error?.localizedDescription ?? "")")
            }
        }
    }
}

extension ViewController: LiveStreamManagerDelegate {
    func liveStreamManager(_ manager: LiveStreamManager, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("成功加入频道: \(channel)")
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didLeaveChannel channel: String, withStats stats: AgoraChannelStats) {
        print("离开频道: \(channel)")
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("远端用户加入: \(uid)")
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("远端用户离开: \(uid)")
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, interactionStatusChanged info: InteractionInfo) {
        print("连麦状态变化: \(info.isConnected)")
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, pkStatusChanged isConnected: Bool, targetRoom: LiveRoom?) {
        print("PK连麦状态: \(isConnected)")
    }
    
    func liveStreamManager(_ manager: LiveStreamManager, didOccurError error: AgoraErrorCode) {
        print("发生错误: \(error.rawValue)")
    }
}
*/
