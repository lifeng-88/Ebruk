//
//  VlAttributionRemoteConfigBox.swift
//  Velo
//
//  T-AF-4: 静态 config 拉取与本地缓存（AppID、DevKey），对齐 glam `AFConfigManager`。
//  从 `{ResBaseURL}/config/{channel_id}.json` 拉取，解析 `apple_app_id`、`apps_flyer_dev_key`；
//  键与 channel_id 关联；仅在本机无有效缓存时拉取。失败不阻塞启动，回退 Info.plist 兜底。
//

import Foundation

/// AF 静态配置 JSON 结构（支持 snake_case 与 camelCase）
private struct AFConfigPayload: Decodable {
    var apple_app_id: String?
    var apps_flyer_dev_key: String?
    var appleAppId: String?
    var appsFlyerDevKey: String?

    var resolvedAppleAppId: String? { apple_app_id ?? appleAppId }
    var resolvedAppsFlyerDevKey: String? { apps_flyer_dev_key ?? appsFlyerDevKey }
}

/// AppsFlyer 配置管理器：拉取并缓存 Apple App ID、AppsFlyer Dev Key
actor VlAttributionRemoteConfigBox {
    static let shared = VlAttributionRemoteConfigBox()

    private let defaults = UserDefaults.standard

    private enum InfoKeys {
        static let appleAppID = "AppsFlyerAppleAppID"
        static let devKey = "AppsFlyerDevKey"
    }

    private init() {}

    // MARK: - Keys (per channel_id)

    private func keyAppleAppID(_ channelId: String) -> String {
        "af_apple_app_id_\(channelId)"
    }

    private func keyAppsFlyerDevKey(_ channelId: String) -> String {
        "af_apps_flyer_dev_key_\(channelId)"
    }

    // MARK: - Public API

    /// 获取 Apple App ID：先读本地，无则拉取再写本地，仍无则 Info.plist 兜底
    func getAppleAppID(channelId: String) async -> String? {
        let effectiveChannel = normalizedChannel(channelId)
        if let cached = nonEmpty(defaults.string(forKey: keyAppleAppID(effectiveChannel))) {
            print("📱 [AFConfig] getAppleAppID: 使用本地缓存 channel=\(effectiveChannel)")
            return cached
        }
        print("📱 [AFConfig] getAppleAppID: 无缓存 channel=\(effectiveChannel)，拉取 config")
        if let (appleAppId, _) = await fetchAndCacheConfig(channelId: effectiveChannel) {
            return appleAppId
        }
        if let fallback = infoPlistValue(InfoKeys.appleAppID) {
            print("📱 [AFConfig] getAppleAppID: 拉取失败，使用 Info.plist 兜底 channel=\(effectiveChannel)")
            return fallback
        }
        print("📱 [AFConfig] getAppleAppID: 拉取失败 channel=\(effectiveChannel)")
        return nil
    }

    /// 获取 AppsFlyer Dev Key：先读本地，无则拉取再写本地，仍无则 Info.plist 兜底
    func getAppsFlyerDevKey(channelId: String) async -> String? {
        let effectiveChannel = normalizedChannel(channelId)
        if let cached = nonEmpty(defaults.string(forKey: keyAppsFlyerDevKey(effectiveChannel))) {
            print("📱 [AFConfig] getAppsFlyerDevKey: 使用本地缓存 channel=\(effectiveChannel)")
            return cached
        }
        print("📱 [AFConfig] getAppsFlyerDevKey: 无缓存 channel=\(effectiveChannel)，拉取 config")
        if let (_, devKey) = await fetchAndCacheConfig(channelId: effectiveChannel) {
            return devKey
        }
        if let fallback = infoPlistValue(InfoKeys.devKey) {
            print("📱 [AFConfig] getAppsFlyerDevKey: 拉取失败，使用 Info.plist 兜底 channel=\(effectiveChannel)")
            return fallback
        }
        print("📱 [AFConfig] getAppsFlyerDevKey: 拉取失败 channel=\(effectiveChannel)")
        return nil
    }

    /// 拉取静态 config 并写入 UserDefaults，失败不抛错
    private func fetchAndCacheConfig(channelId: String) async -> (appleAppId: String, appsFlyerDevKey: String)? {
        let base = ResBaseURL.effective.hasSuffix("/") ? String(ResBaseURL.effective.dropLast()) : ResBaseURL.effective
        let urlString = base.hasPrefix("http") ? "\(base)/config/\(channelId).json" : "http://\(base)/config/\(channelId).json"
        print("📱 [AFConfig] fetchAndCacheConfig: URL=\(urlString)")
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            print("⚠️ [AFConfig] fetchAndCacheConfig: Invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("⚠️ [AFConfig] fetchAndCacheConfig: HTTP status=\((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }
            let payload = try JSONDecoder().decode(AFConfigPayload.self, from: data)
            guard let appleAppId = nonEmpty(payload.resolvedAppleAppId),
                  let devKey = nonEmpty(payload.resolvedAppsFlyerDevKey) else {
                print("⚠️ [AFConfig] fetchAndCacheConfig: 缺少 apple_app_id 或 apps_flyer_dev_key")
                return nil
            }
            defaults.set(appleAppId, forKey: keyAppleAppID(channelId))
            defaults.set(devKey, forKey: keyAppsFlyerDevKey(channelId))
            print("✅ [AFConfig] fetchAndCacheConfig: 成功 channel=\(channelId) appleAppId=\(appleAppId.prefix(12))...")
            return (appleAppId, devKey)
        } catch {
            print("⚠️ [AFConfig] fetchAndCacheConfig: 请求失败 \(error.localizedDescription)")
            return nil
        }
    }

    private func normalizedChannel(_ channelId: String) -> String {
        let trimmed = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppConfig.buildDefaultChannelId : trimmed
    }

    private func infoPlistValue(_ key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        return nonEmpty(raw)
    }

    private func nonEmpty(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) else { return nil }
        return trimmed
    }
}
