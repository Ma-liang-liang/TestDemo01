//
//  BluetoothTransferProtocol.swift
//  TestDemo01
//
//  Created by Codex on 2026/7/11.
//

/// 本文件实现了蓝牙数据传输的应用层协议：
/// 1. BluetoothPacketProgress —— 传输进度模型
/// 2. BluetoothTransferReliability —— 可靠性级别（fireAndForget / applicationAck）
/// 3. BluetoothTransferOptions —— 传输配置（角色、窗口、重试等）
/// 4. BluetoothProtocolFrame / FrameType —— 应用层帧结构与帧类型
/// 5. BluetoothProtocolCodec —— 帧的拆包、编码、解码（含 CRC32 校验）
/// 6. Data 扩展 —— 大端字节序的读写工具与 CRC32 计算

import CoreBluetooth
import Foundation

// MARK: - 传输进度

/// 传输进度模型，记录已发送和总字节数。
struct BluetoothPacketProgress {
    /// 已确认发送（ACK）的字节数
    let sentBytes: Int
    /// 本次传输的总字节数
    let totalBytes: Int

    /// 传输完成比例 [0, 1]
    var ratio: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(sentBytes) / Double(totalBytes)
    }
}

// MARK: - 可靠性级别

/// 传输可靠性级别，决定是否需要外设回 ACK。
enum BluetoothTransferReliability {
    /// 只依赖 CoreBluetooth 写入队列，适合高频实时数据或设备不支持业务 ACK 的场景。
    /// 发出去就不管了，不等待确认，不重试。
    case fireAndForget
    /// 需要外设通过 notify 回 ACK，适合文件、OTA、关键配置等强一致传输。
    /// 每个数据包都要等外设确认，超时自动重试，达到最大重试次数后报错。
    case applicationAck
}

// MARK: - 传输配置

/// 传输配置选项，控制可靠传输的各种参数。
struct BluetoothTransferOptions {
    /// 使用哪个特征角色发送数据
    var role: BluetoothCharacteristicRole = .dataWrite
    /// 可靠性级别
    var reliability: BluetoothTransferReliability = .applicationAck
    /// 单帧最大 payload 长度，nil 表示自动计算（MTU - headerLength）
    var maxPayloadLength: Int?
    /// ACK 窗口大小：同时允许在途未确认的数据包数量
    /// 值越大吞吐越高，但占用的蓝牙缓冲也越多
    var ackWindow: Int = 6
    /// 单个包最大重试次数，超过后判定传输失败
    var maxRetries: Int = 3
    /// 等待 ACK 的超时时间（秒），超时后触发重试
    var ackTimeout: TimeInterval = 1.5
    /// 写入方式：.withResponse 更可靠，.withoutResponse 更快
    /// nil 表示根据特征属性自动选择
    var writeType: CBCharacteristicWriteType?
    /// 是否使用应用层帧（包头+CRC），关闭后走裸数据写入
    var useApplicationFrame: Bool = true
    /// 是否支持断点续传（默认 false）
    /// 开启后：断连时保存已确认的 offset，重连后自动从断点继续传输
    /// 注意：开启时原始数据会保留在内存中直到传输完成或取消
    var supportsResume: Bool = false
}

// MARK: - 帧类型

/// 应用层帧类型，区分不同用途的数据包。
enum BluetoothProtocolFrameType: UInt8 {
    /// 数据帧：携带实际 payload
    case data = 1
    /// 确认帧：外设回传给 App，表示某个序号的数据包已收到
    case ack = 2
    /// 完成帧：标记整个传输结束（当前未使用，预留）
    case complete = 3
    /// 续传请求帧：请求从某个 offset 继续传输（当前未使用，预留）
    case resumeRequest = 4
}

// MARK: - 帧结构

/// 应用层数据帧结构。
///
/// 帧布局（大端序）：
/// ```
/// | magic(2B) | version(1B) | type(1B) | sequence(4B) | offset(4B) | totalLength(4B) | payloadLen(2B) | crc32(4B) | payload(NB) |
/// | 0xA55A   | 0x01        |          |             |            |                  |               |          |              |
/// ```
/// 头部固定 22 字节，payload 长度可变。
struct BluetoothProtocolFrame {
    /// 魔数，用于帧同步（接收方据此判断数据是否为合法帧）
    static let magic: UInt16 = 0xA55A
    /// 协议版本号，用于未来升级兼容
    static let version: UInt8 = 1
    /// 头部固定长度：magic(2) + version(1) + type(1) + sequence(4) + offset(4) + totalLength(4) + payloadLen(2) + crc32(4) = 22
    static let headerLength = 22

    /// 帧类型
    let type: BluetoothProtocolFrameType
    /// 帧序号（从 0 递增），用于 ACK 匹配和重排序
    let sequence: UInt32
    /// 该帧 payload 在整个数据中的字节偏移
    let offset: UInt32
    /// 整个传输数据的总长度（所有帧的 payload 拼接后的大小）
    let totalLength: UInt32
    /// 实际负载
    let payload: Data
}

// MARK: - 帧编解码器

/// 帧编解码器，负责将原始数据拆分为帧、编码为字节流、以及从字节流解码出帧。
enum BluetoothProtocolCodec {

    /// 将一段原始数据拆分为多个数据帧。
    /// - Parameters:
    ///   - data: 原始数据
    ///   - maxPayloadLength: 每帧 payload 的最大长度
    /// - Returns: 拆分后的帧数组
    static func makeDataFrames(data: Data, maxPayloadLength: Int) -> [BluetoothProtocolFrame] {
        // 限制单帧 payload 不超过 UInt16.max（帧头中 payloadLen 字段为 UInt16）
        let safeMaxPayload = min(maxPayloadLength, Int(UInt16.max))
        // 空数据也要发一帧，让接收方知道传输开始和结束
        guard !data.isEmpty else {
            return [
                BluetoothProtocolFrame(type: .data, sequence: 0, offset: 0, totalLength: 0, payload: Data())
            ]
        }

        var frames: [BluetoothProtocolFrame] = []
        var sequence: UInt32 = 0
        var offset = 0

        // 按 safeMaxPayload 逐块切片，每块成为一个数据帧
        while offset < data.count {
            let end = min(offset + safeMaxPayload, data.count)
            let payload = data.subdata(in: offset..<end)
            frames.append(BluetoothProtocolFrame(
                type: .data,
                sequence: sequence,
                offset: UInt32(offset),
                totalLength: UInt32(data.count),
                payload: payload
            ))
            sequence += 1
            offset = end
        }

        return frames
    }

    /// 构造一个 ACK 帧。
    /// - Parameters:
    ///   - sequence: 确认的数据帧序号
    ///   - offset: 确认的数据帧偏移
    ///   - totalLength: 传输总长度
    /// - Returns: ACK 帧（payload 为空）
    static func makeAck(sequence: UInt32, offset: UInt32, totalLength: UInt32) -> BluetoothProtocolFrame {
        BluetoothProtocolFrame(
            type: .ack,
            sequence: sequence,
            offset: offset,
            totalLength: totalLength,
            payload: Data()
        )
    }

    /// 将帧编码为字节流（大端序）。
    /// - Parameter frame: 待编码的帧
    /// - Returns: 编码后的字节数据，可直接写入蓝牙特征
    static func encode(_ frame: BluetoothProtocolFrame) -> Data {
        var data = Data()
        data.appendUInt16BE(BluetoothProtocolFrame.magic)     // 魔数：帧同步标识
        data.appendUInt8(BluetoothProtocolFrame.version)      // 版本号
        data.appendUInt8(frame.type.rawValue)                  // 帧类型
        data.appendUInt32BE(frame.sequence)                    // 序号
        data.appendUInt32BE(frame.offset)                      // 偏移
        data.appendUInt32BE(frame.totalLength)                 // 总长度
        // payload 长度上限为 UInt16.max，超出说明切分有误
        let payloadLen = min(frame.payload.count, Int(UInt16.max))
        data.appendUInt16BE(UInt16(payloadLen))                 // payload 长度
        data.appendUInt32BE(frame.payload.crc32())             // CRC32 校验
        data.append(frame.payload)                             // 实际负载
        return data
    }

    /// 从字节流解码出帧。
    /// 会校验魔数、版本号、长度和 CRC32，任一不匹配则返回 nil。
    /// - Parameter data: 从蓝牙特征读到的原始字节
    /// - Returns: 解码成功的帧，数据不合法时返回 nil
    static func decode(_ data: Data) -> BluetoothProtocolFrame? {
        // 1. 长度至少要能装下头部
        guard data.count >= BluetoothProtocolFrame.headerLength else { return nil }
        // 2. 校验魔数
        guard data.readUInt16BE(at: 0) == BluetoothProtocolFrame.magic else { return nil }
        // 3. 校验版本号
        guard data.readUInt8(at: 2) == BluetoothProtocolFrame.version else { return nil }
        // 4. 逐字段解析头部
        guard let typeRaw = data.readUInt8(at: 3),
              let type = BluetoothProtocolFrameType(rawValue: typeRaw),
              let sequence = data.readUInt32BE(at: 4),
              let offset = data.readUInt32BE(at: 8),
              let totalLength = data.readUInt32BE(at: 12),
              let payloadLength = data.readUInt16BE(at: 16),
              let expectedCRC = data.readUInt32BE(at: 18) else { return nil }

        // 5. 截取 payload 并校验长度
        let payloadStart = BluetoothProtocolFrame.headerLength
        let payloadEnd = payloadStart + Int(payloadLength)
        guard data.count >= payloadEnd else { return nil }

        let payload = data.subdata(in: payloadStart..<payloadEnd)
        // 6. CRC32 校验，防止数据损坏
        guard payload.crc32() == expectedCRC else { return nil }

        return BluetoothProtocolFrame(
            type: type,
            sequence: sequence,
            offset: offset,
            totalLength: totalLength,
            payload: payload
        )
    }
}

// MARK: - Data 大端序读写扩展

/// Data 的大端序读写扩展，用于帧的编码/解码。
/// 蓝牙协议通常使用大端序（高位在前），与网络字节序一致。
private extension Data {

    // MARK: 写入

    /// 追加一个 UInt8 字节
    mutating func appendUInt8(_ value: UInt8) {
        append(value)
    }

    /// 追加一个 UInt16（大端序：高字节在前）
    mutating func appendUInt16BE(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xFF))   // 高 8 位
        append(UInt8(value & 0xFF))          // 低 8 位
    }

    /// 追加一个 UInt32（大端序：高位在前，低位在后）
    mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xFF)) // 第 4 字节（最高位）
        append(UInt8((value >> 16) & 0xFF)) // 第 3 字节
        append(UInt8((value >> 8) & 0xFF))  // 第 2 字节
        append(UInt8(value & 0xFF))         // 第 1 字节（最低位）
    }

    // MARK: 读取

    /// 读取指定位置的一个 UInt8 字节
    func readUInt8(at index: Int) -> UInt8? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }

    /// 读取指定位置起的一个 UInt16（大端序）
    func readUInt16BE(at index: Int) -> UInt16? {
        guard let b0 = readUInt8(at: index),
              let b1 = readUInt8(at: index + 1) else { return nil }
        return (UInt16(b0) << 8) | UInt16(b1)
    }

    /// 读取指定位置起的一个 UInt32（大端序）
    func readUInt32BE(at index: Int) -> UInt32? {
        guard let b0 = readUInt8(at: index),
              let b1 = readUInt8(at: index + 1),
              let b2 = readUInt8(at: index + 2),
              let b3 = readUInt8(at: index + 3) else { return nil }
        return (UInt32(b0) << 24) | (UInt32(b1) << 16) | (UInt32(b2) << 8) | UInt32(b3)
    }

    /// 计算 CRC32 校验值。
    /// 使用多项式 0xEDB88320（IEEE 802.3 标准），初始值 0xFFFFFFFF，最终异或 0xFFFFFFFF。
    /// 用于检测数据在传输过程中是否发生位翻转或损坏。
    func crc32() -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in self {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                if crc & 1 == 1 {
                    crc = (crc >> 1) ^ 0xEDB8_8320
                } else {
                    crc >>= 1
                }
            }
        }
        return crc ^ 0xFFFF_FFFF
    }
}
