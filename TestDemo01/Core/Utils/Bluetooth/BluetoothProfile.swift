//
//  BluetoothProfile.swift
//  TestDemo01
//
//  Created by Codex on 2026/7/11.
//

/// 本文件定义了蓝牙通信的"协议画像"体系：
/// 1. BluetoothCharacteristicRole —— 用业务角色代替裸 UUID，降低耦合
/// 2. BluetoothCharacteristicProfile —— 单个特征在设备协议中的完整定义
/// 3. BluetoothDeviceProfile —— 一类硬件设备的蓝牙协议画像（扫描/服务/特征集合）
/// 4. BluetoothConnectionState —— 连接状态机枚举
/// 5. BluetoothMetricSnapshot —— 连接与传输的运行时指标快照

import CoreBluetooth
import Foundation

// MARK: - 特征角色

/// 特征的业务角色。线上项目不要直接到处传 characteristic UUID，
/// 而是通过角色表达"这条通道用来干什么"，后续换硬件协议时 App 层更稳。
enum BluetoothCharacteristicRole: String, Hashable {
    /// 命令写入通道，用于发送简短指令（如 PING、开关灯等）
    case commandWrite
    /// 数据写入通道，用于发送大块数据（如文件、OTA 固件包等）
    case dataWrite
    /// 通知监听通道，外设通过此通道主动推送数据给 App
    case notify
    /// 只读通道，App 主动读取外设的值
    case read
}

// MARK: - 特征画像

/// 单个特征在设备协议中的定义。
/// 描述了某个特征的 UUID、所属服务、是否需要订阅通知以及偏好写入方式。
struct BluetoothCharacteristicProfile {
    /// 该特征的业务角色
    let role: BluetoothCharacteristicRole
    /// 所属服务的 UUID
    let serviceUUID: CBUUID
    /// 特征自身的 UUID
    let characteristicUUID: CBUUID
    /// 是否需要订阅 notify/indicate
    let enableNotify: Bool
    /// 偏好的写入方式（.withResponse 更可靠，.withoutResponse 更快）
    let preferredWriteType: CBCharacteristicWriteType

    init(
        role: BluetoothCharacteristicRole,
        serviceUUID: CBUUID,
        characteristicUUID: CBUUID,
        enableNotify: Bool = false,
        preferredWriteType: CBCharacteristicWriteType = .withoutResponse
    ) {
        self.role = role
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        self.enableNotify = enableNotify
        self.preferredWriteType = preferredWriteType
    }
}

// MARK: - 设备协议画像

/// 一类硬件设备的蓝牙协议画像。
/// 生产中建议每类设备都配置明确的 service/characteristic，而不是 discoverServices(nil)。
/// 这样可以：减少扫描耗电、加快连接速度、避免发现无关特征。
struct BluetoothDeviceProfile {
    /// 画像名称，用于日志和调试
    let name: String
    /// 扫描时过滤的 service UUID，nil 表示全量扫描
    let scanServiceUUIDs: [CBUUID]?
    /// 连接后需要发现的服务列表，nil 表示发现全部服务
    let serviceUUIDs: [CBUUID]?
    /// 该设备画像包含的所有特征定义
    let characteristics: [BluetoothCharacteristicProfile]

    init(
        name: String,
        scanServiceUUIDs: [CBUUID]?,
        serviceUUIDs: [CBUUID]?,
        characteristics: [BluetoothCharacteristicProfile]
    ) {
        self.name = name
        self.scanServiceUUIDs = scanServiceUUIDs
        self.serviceUUIDs = serviceUUIDs
        self.characteristics = characteristics
    }

    /// 根据角色查找对应的特征画像
    /// - Parameter role: 业务角色（如 .commandWrite）
    /// - Returns: 匹配到的特征画像，找不到返回 nil
    func characteristic(for role: BluetoothCharacteristicRole) -> BluetoothCharacteristicProfile? {
        characteristics.first { $0.role == role }
    }

    /// 获取某个服务下所有需要发现的特征 UUID
    /// - Parameter serviceUUID: 目标服务 UUID
    /// - Returns: 特征 UUID 数组，该服务下没有定义特征时返回 nil（表示发现全部）
    func characteristicUUIDs(for serviceUUID: CBUUID) -> [CBUUID]? {
        let uuids = characteristics
            .filter { $0.serviceUUID == serviceUUID }
            .map(\.characteristicUUID)
        return uuids.isEmpty ? nil : uuids
    }

    /// 根据实际发现的 CBCharacteristic 反查业务角色
    /// - Parameters:
    ///   - characteristic: CoreBluetooth 返回的特征对象
    ///   - service: 该特征所属的服务
    /// - Returns: 匹配到的业务角色，未在画像中定义则返回 nil
    func role(for characteristic: CBCharacteristic, service: CBService) -> BluetoothCharacteristicRole? {
        characteristics.first {
            $0.serviceUUID == service.uuid && $0.characteristicUUID == characteristic.uuid
        }?.role
    }

    /// 通用演示模式：允许全量扫描和自动选择第一个可用特征。
    /// 这只适合 Demo/调试；线上业务应替换成明确 UUID 的 profile。
    static let genericDemo = BluetoothDeviceProfile(
        name: "Generic BLE Demo",
        scanServiceUUIDs: nil,
        serviceUUIDs: nil,
        characteristics: []
    )
}

// MARK: - 连接状态机

/// 蓝牙连接的状态机枚举，贯穿整个连接生命周期。
/// 状态流转：idle → scanning → connecting → discovering → ready → disconnecting → disconnected
/// 异常路径：任意状态 → failed / reconnecting
enum BluetoothConnectionState: Equatable {
    /// 空闲，未开始任何操作
    case idle
    /// 正在扫描附近设备
    case scanning
    /// 正在连接指定设备（参数为设备 UUID）
    case connecting(UUID)
    /// 已连接，正在发现服务和特征
    case discovering(UUID)
    /// 服务和特征已就绪，可以开始数据传输
    case ready(UUID)
    /// 正在断开连接
    case disconnecting(UUID)
    /// 已断开连接（参数可能为 nil 表示无记录的设备）
    case disconnected(UUID?)
    /// 正在重连（参数为设备 UUID 和当前重试次数）
    case reconnecting(UUID, attempt: Int)
    /// 连接失败（参数为错误描述）
    case failed(String)
}

// MARK: - 运行时指标

/// 蓝牙连接与传输的运行时指标快照，用于 UI 展示和性能分析。
struct BluetoothMetricSnapshot {
    /// 连接开始的时间戳
    var connectStartedAt: Date?
    /// 特征就绪（可传输）的时间戳
    var readyAt: Date?
    /// 已尝试重连的次数
    var reconnectAttempts: Int = 0
    /// 已发送的字节数
    var transmittedBytes: Int = 0
    /// 已接收的字节数
    var receivedBytes: Int = 0
    /// 最近一次扫描到的 RSSI 信号强度
    var lastRSSI: Int?
    /// 当前外设支持的最大写入长度（由 maximumWriteValueLength 决定）
    var maximumWriteLength: Int = 20

    /// 从开始连接到特征就绪的耗时（秒），用于评估连接性能
    var connectionCost: TimeInterval? {
        guard let connectStartedAt, let readyAt else { return nil }
        return readyAt.timeIntervalSince(connectStartedAt)
    }
}
