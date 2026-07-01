//
//  AppConfig.swift
//  Velo
//

import Foundation

final class AppConfig: @unchecked Sendable {
    static let shared = AppConfig()

    private static let channelKey = "ChannelId"
    private static let isTestKey = "isTest"

    /// Info.plist `ChannelId` 未配置或无效时的渠道 ID。**DEBUG：IOS10052（价目/配置调试）；Release：IOS10056。**
    static var buildDefaultChannelId: String {
        "IOS10056"
    }

    private init() {}

    /// Info.plist `isTest`：1 表示联调测试；**仅 DEBUG 编译**且 `isTest == 1` 时使用固定 `devId`，否则走 Keychain 真实设备 ID。未配置时视为 0。
    static var isTest: Int {
        if let n = Bundle.main.object(forInfoDictionaryKey: isTestKey) as? Int { return n }
        if let n = Bundle.main.object(forInfoDictionaryKey: isTestKey) as? NSNumber { return n.intValue }
        if let s = Bundle.main.object(forInfoDictionaryKey: isTestKey) as? String,
           let n = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return n
        }
        return 0
    }

    /// DEBUG 且 `isTest == 1` 时，`DeviceManager` 使用固定联调 `devId`。
    static var usesDebugFixedDeviceId: Bool {
        #if DEBUG
        return isTest == 1
        #else
        return false
        #endif
    }

    func getChannel() async -> String {
        if let v = Bundle.main.object(forInfoDictionaryKey: "AppChannel") as? String {
            let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty, !(t.hasPrefix("$(") && t.hasSuffix(")")) { return t }
        }
        if let v = Bundle.main.object(forInfoDictionaryKey: Self.channelKey) as? String {
            let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty, !(t.hasPrefix("$(") && t.hasSuffix(")")) { return t }
        }
        return Self.buildDefaultChannelId
    }
}
