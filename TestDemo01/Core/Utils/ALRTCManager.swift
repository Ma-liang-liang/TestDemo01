import AgoraRtcKit

protocol ALRTCManagerDelegate: AnyObject {
    // 通用事件
    func rtcManager(_ manager: ALRTCManager, didJoinedOfUid uid: UInt, in channel: String)
    func rtcManager(_ manager: ALRTCManager, didOfflineOfUid uid: UInt, in channel: String)
    func rtcManager(_ manager: ALRTCManager, didError error: ALRTCManager.RTCError)
    func rtcManager(_ manager: ALRTCManager, networkQuality uid: UInt, quality: AgoraNetworkQuality, in channel: String)
    
    // PK相关事件
    func rtcManager(_ manager: ALRTCManager, didReceivePKRequestFrom uid: UInt, in channel: String)
    func rtcManager(_ manager: ALRTCManager, pkStateDidChange state: ALRTCManager.PKState)
    
    // 连麦相关事件
    func rtcManager(_ manager: ALRTCManager, didReceiveMicRequestFrom uid: UInt, in channel: String)
    func rtcManager(_ manager: ALRTCManager, micStateChanged state: ALRTCManager.MicState, forUid uid: UInt)
    func rtcManager(_ manager: ALRTCManager, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, in channel: String)
}

class ALRTCManager: NSObject {
    
    // MARK: - 枚举定义
    enum UserRole {
        case broadcaster
        case audience
    }
    
    enum PKState: Equatable {
        case idle
        case requesting(targetChannel: String, targetUid: UInt)
        case inProgress(pkChannels: [String], pkUids: [UInt])
    }
    
    enum MicState {
        case idle
        case requesting
        case active
        case rejected
    }
    
    enum RTCError: Error {
        case joinFailed(channel: String, code: Int)
        case pkStartFailed(reason: String)
        case invalidState(operation: String)
        case tokenExpired(channel: String)
        case connectionLost
        case micUpFailed(reason: String)
    }
    
    // MARK: - 嵌套结构
    struct ConnectionInfo {
        let connection: AgoraRtcConnection
        var mediaOptions: AgoraRtcChannelMediaOptions
        var token: String?
        var role: UserRole
    }
    
    struct AgoraConfig {
        let appId: String
        var uid: UInt
    }
    
    struct ActiveMicUser {
        let uid: UInt
        var state: MicState
        var channel: String
    }
    
    // MARK: - 属性
    private var agoraKit: AgoraRtcEngineKit!
    private var config: AgoraConfig
    private var connections: [String: ConnectionInfo] = [:]
    private var pkState: PKState = .idle
    private var activeMicUsers: [UInt: ActiveMicUser] = [:]
    private var pendingMicRequests: [UInt: String] = [:]
    weak var delegate: ALRTCManagerDelegate?
    
    // 当前主频道连接（主播所在频道）
    private var mainChannel: String? {
        didSet {
            if mainChannel == nil {
                leaveAllChannels()
            }
        }
    }
    
    // MARK: - 初始化
    init(config: AgoraConfig) {
        var safeConfig = config
        if safeConfig.uid == 0 {
            safeConfig.uid = UInt.random(in: 100000...999999)
        }
        self.config = safeConfig
        super.init()
        initializeAgoraEngine()
    }
    
    private func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: config.appId, delegate: self)
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.enableVideo()
        agoraKit.enableAudio()
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
    }
    
    // MARK: - 频道管理
    func startBroadcast(channel: String, token: String? = nil, completion: @escaping (Result<UInt, RTCError>) -> Void) {
        guard connections[channel] == nil else {
            completion(.failure(.invalidState(operation: "重复加入频道")))
            return
        }
        
        mainChannel = channel
        
        let connection = AgoraRtcConnection(channelId: channel, localUid: Int(config.uid))
        
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.autoSubscribeAudio = true
        mediaOptions.autoSubscribeVideo = true
        mediaOptions.publishCameraTrack = true
        mediaOptions.publishMicrophoneTrack = true
        mediaOptions.clientRoleType = .broadcaster
        
        let connectionInfo = ConnectionInfo(
            connection: connection,
            mediaOptions: mediaOptions,
            token: token,
            role: .broadcaster
        )
        
        connections[channel] = connectionInfo
        
        let joinResult = agoraKit.joinChannelEx(
            byToken: token,
            connection: connection,
            delegate: self,
            mediaOptions: mediaOptions,
            joinSuccess: nil
        )
        
        if joinResult != 0 {
            connections.removeValue(forKey: channel)
            completion(.failure(.joinFailed(channel: channel, code: Int(joinResult))))
        } else {
            completion(.success(config.uid))
        }
    }
    
    func joinChannelAsAudience(channel: String, token: String? = nil, completion: @escaping (Result<UInt, RTCError>) -> Void) {
        guard connections[channel] == nil else {
            completion(.failure(.invalidState(operation: "重复加入频道")))
            return
        }
        
        let connection = AgoraRtcConnection(channelId: channel, localUid: Int(config.uid))
        
        var mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.autoSubscribeAudio = true
        mediaOptions.autoSubscribeVideo = true
        mediaOptions.publishCameraTrack = false
        mediaOptions.publishMicrophoneTrack = false
        mediaOptions.clientRoleType = .audience
        
        let connectionInfo = ConnectionInfo(
            connection: connection,
            mediaOptions: mediaOptions,
            token: token,
            role: .audience
        )
        
        connections[channel] = connectionInfo
        
        let joinResult = agoraKit.joinChannelEx(
            byToken: token,
            connection: connection,
            delegate: self,
            mediaOptions: mediaOptions,
            joinSuccess: nil
        )
        
        if joinResult != 0 {
            connections.removeValue(forKey: channel)
            completion(.failure(.joinFailed(channel: channel, code: Int(joinResult))))
        } else {
            completion(.success(config.uid))
        }
    }
    
    func leaveChannel(_ channel: String) {
        guard let connectionInfo = connections[channel] else { return }
        
        // 处理PK状态
        if case .inProgress(let pkChannels, _) = pkState, pkChannels.contains(channel) {
            removePKChannel(channel)
        }
        
        // 处理连麦状态
        if let micUser = activeMicUsers[config.uid], micUser.channel == channel {
            activeMicUsers.removeValue(forKey: config.uid)
        }
        
        agoraKit.leaveChannelEx(connectionInfo.connection)
        connections.removeValue(forKey: channel)
        
        if channel == mainChannel {
            leaveAllChannels()
            mainChannel = nil
        }
    }
    
    private func leaveAllChannels() {
        for (_, connectionInfo) in connections {
            agoraKit.leaveChannelEx(connectionInfo.connection)
        }
        connections.removeAll()
        pkState = .idle
        activeMicUsers.removeAll()
    }
    
    // MARK: - 多主播PK功能
    func sendPKRequest(to targetChannel: String, targetUid: UInt) {
        guard let mainChannel = mainChannel else {
            delegate?.rtcManager(self, didError: .invalidState(operation: "未加入主频道"))
            return
        }
        
        pkState = .requesting(targetChannel: targetChannel, targetUid: targetUid)
        sendCustomMessage("PK_REQUEST:\(config.uid):\(mainChannel)", to: targetUid, in: targetChannel)
    }
    
    func acceptPKRequest(from uid: UInt, in channel: String) {
        guard case .requesting(let targetChannel, let targetUid) = pkState,
              targetUid == uid else {
            delegate?.rtcManager(self, didError: .invalidState(operation: "无效的PK请求"))
            return
        }
        
        // 加入目标PK频道
        joinPKChannel(channel) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // 更新PK状态
                self.updatePKStateWithNewChannel(channel, uid: uid)
                self.sendCustomMessage("PK_ACCEPT:\(self.config.uid)", to: uid, in: channel)
                
            case .failure(let error):
                self.delegate?.rtcManager(self, didError: error)
                self.pkState = .idle
            }
        }
    }
    
    func joinPKChannel(_ channel: String, completion: @escaping (Result<Void, RTCError>) -> Void) {
        if connections[channel] != nil {
            completion(.success(()))
            return
        }
        
        let connection = AgoraRtcConnection(channelId: channel, localUid: Int(config.uid))
        
        let mediaOptions = AgoraRtcChannelMediaOptions()
        mediaOptions.autoSubscribeAudio = true
        mediaOptions.autoSubscribeVideo = true
        mediaOptions.publishCameraTrack = false
        mediaOptions.publishMicrophoneTrack = false
        mediaOptions.clientRoleType = .audience
        
        let joinResult = agoraKit.joinChannelEx(
            byToken: nil,
            connection: connection,
            delegate: self,
            mediaOptions: mediaOptions,
            joinSuccess: nil
        )
        if joinResult == 0 {
            connections[channel] = ConnectionInfo(
                connection: connection,
                mediaOptions: mediaOptions,
                token: nil,
                role: .audience
            )
            completion(.success(()))
        } else {
            completion(.failure(.joinFailed(channel: channel, code: Int(joinResult))))
        }
    }
    
    private func updatePKStateWithNewChannel(_ newChannel: String, uid: UInt) {
        switch pkState {
        case .inProgress(var channels, var uids):
            if !channels.contains(newChannel) {
                channels.append(newChannel)
                uids.append(uid)
                pkState = .inProgress(pkChannels: channels, pkUids: uids)
            }
            
        default:
            pkState = .inProgress(pkChannels: [newChannel], pkUids: [uid])
        }
        
        delegate?.rtcManager(self, pkStateDidChange: pkState)
    }
    
    func removePKChannel(_ channel: String) {
        guard case .inProgress(var channels, var uids) = pkState,
              let index = channels.firstIndex(of: channel) else {
            return
        }
        
        channels.remove(at: index)
        uids.remove(at: index)
        
        if channels.isEmpty {
            pkState = .idle
        } else {
            pkState = .inProgress(pkChannels: channels, pkUids: uids)
        }
        
        delegate?.rtcManager(self, pkStateDidChange: pkState)
    }
    
    func stopAllPK() {
        guard case .inProgress(let channels, _) = pkState else { return }
        
        for channel in channels {
            if let connection = connections[channel]?.connection {
                agoraKit.leaveChannelEx(connection)
                connections.removeValue(forKey: channel)
            }
        }
        
        pkState = .idle
        delegate?.rtcManager(self, pkStateDidChange: pkState)
    }
    
    // MARK: - 观众连麦功能
    func requestMicUp(in channel: String) {
        guard let mainChannel = mainChannel,
              connections[channel]?.role == .audience else {
            return
        }
        
        // 发送连麦请求
        sendCustomMessage("MIC_REQUEST:\(config.uid)", to: 0, in: channel)
        
        // 更新本地状态
        activeMicUsers[config.uid] = ActiveMicUser(
            uid: config.uid,
            state: .requesting,
            channel: channel
        )
        
        delegate?.rtcManager(
            self,
            micStateChanged: .requesting,
            forUid: config.uid
        )
    }
    
    func acceptMicRequest(from uid: UInt, in channel: String) {
        guard let micUser = activeMicUsers[uid] ?? pendingMicRequests[uid].map({
            ActiveMicUser(uid: uid, state: .requesting, channel: $0)
        }) else {
            return
        }
        
        // 通知观众上麦
        sendCustomMessage("MIC_ACCEPT:\(uid)", to: uid, in: micUser.channel)
        
        // 更新状态
        activeMicUsers[uid] = ActiveMicUser(
            uid: uid,
            state: .active,
            channel: micUser.channel
        )
        
        delegate?.rtcManager(
            self,
            micStateChanged: .active,
            forUid: uid
        )
        
        pendingMicRequests.removeValue(forKey: uid)
    }
    
    func rejectMicRequest(from uid: UInt) {
        guard let channel = pendingMicRequests[uid] else { return }
        
        sendCustomMessage("MIC_REJECT:\(uid)", to: uid, in: channel)
        
        if uid == config.uid {
            activeMicUsers[config.uid] = ActiveMicUser(
                uid: config.uid,
                state: .rejected,
                channel: channel
            )
            
            delegate?.rtcManager(
                self,
                micStateChanged: .rejected,
                forUid: config.uid
            )
        }
        
        pendingMicRequests.removeValue(forKey: uid)
    }
    
    func startLocalBroadcast(in channel: String) {
        guard var connectionInfo = connections[channel],
              connectionInfo.role == .audience else {
            return
        }
        
        // 更新媒体选项
        connectionInfo.mediaOptions.publishCameraTrack = true
        connectionInfo.mediaOptions.publishMicrophoneTrack = true
        connectionInfo.mediaOptions.clientRoleType = .broadcaster
        
        // 更新SDK设置
        let result = agoraKit.updateChannelEx(
            with: connectionInfo.mediaOptions,
            connection: connectionInfo.connection
        )
        
        if result == 0 {
            // 更新本地状态
            connections[channel]?.role = .broadcaster
            connections[channel]?.mediaOptions = connectionInfo.mediaOptions
            
            activeMicUsers[config.uid] = ActiveMicUser(
                uid: config.uid,
                state: .active,
                channel: channel
            )
            
            // 启用本地音视频
            agoraKit.enableLocalAudio(true)
            agoraKit.enableLocalVideo(true)
            
            delegate?.rtcManager(
                self,
                micStateChanged: .active,
                forUid: config.uid
            )
        } else {
            delegate?.rtcManager(
                self,
                didError: .micUpFailed(reason: "更新角色失败: \(result)")
            )
        }
    }
    
    func stopLocalBroadcast(in channel: String) {
        guard var connectionInfo = connections[channel],
              connectionInfo.role == .broadcaster else {
            return
        }
        
        // 更新媒体选项
        connectionInfo.mediaOptions.publishCameraTrack = false
        connectionInfo.mediaOptions.publishMicrophoneTrack = false
        connectionInfo.mediaOptions.clientRoleType = .audience
        
        // 更新SDK设置
        let result = agoraKit.updateChannelEx(
            with: connectionInfo.mediaOptions,
            connection: connectionInfo.connection
        )
        
        if result == 0 {
            // 更新本地状态
            connections[channel]?.role = .audience
            connections[channel]?.mediaOptions = connectionInfo.mediaOptions
            
            activeMicUsers.removeValue(forKey: config.uid)
            
            // 禁用本地音视频
            agoraKit.enableLocalAudio(false)
            agoraKit.enableLocalVideo(false)
            
            delegate?.rtcManager(
                self,
                micStateChanged: .idle,
                forUid: config.uid
            )
        }
    }
    
    // MARK: - 视频管理 (使用官方API)
    func setupLocalVideo(_ view: UIView) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = config.uid
        canvas.view = view
        canvas.renderMode = .hidden
        agoraKit.setupLocalVideo(canvas)
    }
    
    func setupRemoteVideo(_ view: UIView, for uid: UInt, in channel: String) {
        guard let connection = connections[channel]?.connection else { return }
        
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = view
        canvas.renderMode = .hidden
        
        // 使用官方API设置远程视频
        agoraKit.setupRemoteVideoEx(canvas, connection: connection)
    }
    
    func switchCamera() {
        agoraKit.switchCamera()
    }
    
    // MARK: - 音频管理
    func setMicrophoneEnabled(_ enabled: Bool, for channel: String? = nil) {
        guard let targetChannel = channel ?? mainChannel,
              let connection = connections[targetChannel]?.connection else {
            return
        }
        
        agoraKit.muteLocalAudioStreamEx(!enabled, connection: connection)
    }
    
    func setEarMonitoringEnabled(_ enabled: Bool) {
        agoraKit.enable(inEarMonitoring: enabled)
    }
    
    // MARK: - 信令方法
    private func sendCustomMessage(_ message: String, to uid: UInt, in channel: String) {
        // 实际项目中应使用RTM或自定义信令系统
        print("[信令] 发送消息到频道: \(channel), 用户: \(uid), 内容: \(message)")
        
        // 模拟信令发送
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            self.handleIncomingSignaling(message: message, from: uid, in: channel)
        }
    }
    
    private func handleIncomingSignaling(message: String, from uid: UInt, in channel: String) {
        if message.starts(with: "PK_REQUEST:") {
            let components = message.components(separatedBy: ":")
            if components.count >= 3, let requestUid = UInt(components[1]) {
                delegate?.rtcManager(
                    self,
                    didReceivePKRequestFrom: requestUid,
                    in: channel
                )
            }
        }
        else if message.starts(with: "MIC_REQUEST:") {
            let components = message.components(separatedBy: ":")
            if components.count >= 2, let requestUid = UInt(components[1]) {
                pendingMicRequests[requestUid] = channel
                delegate?.rtcManager(
                    self,
                    didReceiveMicRequestFrom: requestUid,
                    in: channel
                )
            }
        }
        else if message.starts(with: "MIC_ACCEPT:") {
            let components = message.components(separatedBy: ":")
            if components.count >= 2, let acceptedUid = UInt(components[1]),
               acceptedUid == config.uid {
                startLocalBroadcast(in: channel)
            }
        }
        else if message.starts(with: "PK_ACCEPT:") {
            let components = message.components(separatedBy: ":")
            if components.count >= 2, let acceptedUid = UInt(components[1]) {
                if case .requesting = pkState {
                    updatePKStateWithNewChannel(channel, uid: acceptedUid)
                }
            }
        }
    }
    
    // MARK: - 安全清理
    deinit {
        leaveAllChannels()
        AgoraRtcEngineKit.destroy()
        print("ALRTCManager 已销毁")
    }
}

// MARK: - AgoraRtcEngineDelegate
extension ALRTCManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int, in connection: AgoraRtcConnection) {
        // 查找对应的频道
        if let channel = connections.first(where: { $0.value.connection == connection })?.key {
            delegate?.rtcManager(self, didJoinedOfUid: uid, in: channel)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason, in connection: AgoraRtcConnection) {
        // 查找对应的频道
        if let channel = connections.first(where: { $0.value.connection == connection })?.key {
            delegate?.rtcManager(self, didOfflineOfUid: uid, in: channel)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String, in connection: AgoraRtcConnection) {
        // 查找对应的频道
        if let channel = connections.first(where: { $0.value.connection == connection })?.key {
            delegate?.rtcManager(self, didError: .tokenExpired(channel: channel))
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality, in connection: AgoraRtcConnection) {
        // 查找对应的频道
        if let channel = connections.first(where: { $0.value.connection.localUid == uid })?.key {
            let quality = AgoraNetworkQuality(rawValue: max(txQuality.rawValue, rxQuality.rawValue)) ?? .good
            delegate?.rtcManager(self, networkQuality: uid, quality: quality, in: channel)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason, elapsed: Int) {
        // 查找对应的频道
        if let channel = connections.first(where: { $0.value.connection.localUid == uid })?.key {
            delegate?.rtcManager(self, remoteVideoStateChangedOfUid: uid, state: state, in: channel)
        }
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data, in connection: AgoraRtcConnection) {
        guard let message = String(data: data, encoding: .utf8),
              let channel = connections.first(where: { $0.value.connection == connection })?.key else {
            return
        }
        
        handleIncomingSignaling(message: message, from: uid, in: channel)
    }
}
