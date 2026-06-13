//
//  VlRemoteFeatureConfigAPI.swift
//  Velo
//
//  GET /v1/app_config — 对齐 GetAppConfigReq（dev_id/source/channel/version/af_attribution_json）
//

import Foundation

/// 与 `GetAppConfigReq` 一致，仅含 5 个字段（不含 login 的 afId/adId）。
struct AppConfigRequest {
    let devId: String
    let source: String?
    let channel: String?
    let version: String
    let afAttributionJson: String?

    func toRequestParameters() -> [String: Any] {
        var params: [String: Any] = [
            "dev_id": devId,
            "version": version
        ]
        if let source { params["source"] = source }
        if let channel { params["channel"] = channel }
        if let afAttributionJson, !afAttributionJson.isEmpty {
            params["af_attribution_json"] = afAttributionJson
        }
        return params
    }
}

struct AppConfigResponse: Decodable {
    /// 与 ReelMix 一致：**1** A 面 / 直链 IAP；**2** B 面 / 支付 Sheet。
    let type: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case rechargePresentationType = "recharge_presentation_type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fromTypeKey = Self.decodeFlexibleInt(from: c, forKey: .type)
        let fromSnake = Self.decodeFlexibleInt(from: c, forKey: .rechargePresentationType)
        type = fromTypeKey ?? fromSnake
    }

    private static func decodeFlexibleInt(from c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Int? {
        if let v = try? c.decode(Int.self, forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key), let v = Int(s) { return v }
        if let i32 = try? c.decode(Int32.self, forKey: key) { return Int(i32) }
        return nil
    }
}

/// `/v1/app_config` 本地持久化（A/B 面 + B 面充值分支共用，对齐 ReelMix）。
enum AppConfigPersistence {
    static let presentationTypeKey = "ebruk.v1.app_config.presentation_type"
    static let fetchSucceededKey = "ebruk.v1.app_config.fetch_succeeded"
    static let lastRemoteRefreshKey = "ebruk.v1.app_config.last_remote_refresh"

    private static let legacyVeloPresentationTypeKey = "velo.v1.app_config.presentation_type"
    private static let legacyVeloFetchSucceededKey = "velo.v1.app_config.fetch_succeeded"
    private static let legacyVeloLastRefreshKey = "velo.v1.app_config.last_remote_refresh"
    private static let legacyVersionConfigKey = "velo.v1.version_config.presentation_type"
    private static let legacyAppVersionPresentationKey = "ebruk.v1.app_version.presentation_type"
    private static let legacyAppVersionFetchKey = "ebruk.v1.app_version.fetch_succeeded"
    private static let legacyAppVersionRefreshKey = "ebruk.v1.app_version.last_remote_refresh"

    static func migrateLegacyKeysIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: fetchSucceededKey) else { return }

        if defaults.bool(forKey: legacyVeloFetchSucceededKey),
           let n = defaults.object(forKey: legacyVeloPresentationTypeKey) as? Int,
           n == 1 || n == 2 {
            defaults.set(n, forKey: presentationTypeKey)
            defaults.set(true, forKey: fetchSucceededKey)
            if defaults.object(forKey: legacyVeloLastRefreshKey) != nil {
                defaults.set(defaults.double(forKey: legacyVeloLastRefreshKey), forKey: lastRemoteRefreshKey)
            }
            return
        }

        if defaults.bool(forKey: legacyAppVersionFetchKey),
           let n = defaults.object(forKey: legacyAppVersionPresentationKey) as? Int,
           n == 1 || n == 2 {
            defaults.set(n, forKey: presentationTypeKey)
            defaults.set(true, forKey: fetchSucceededKey)
            if defaults.object(forKey: legacyAppVersionRefreshKey) != nil {
                defaults.set(defaults.double(forKey: legacyAppVersionRefreshKey), forKey: lastRemoteRefreshKey)
            }
            return
        }

        if let n = defaults.object(forKey: legacyVersionConfigKey) as? Int, n == 1 || n == 2 {
            defaults.set(n, forKey: presentationTypeKey)
            defaults.set(true, forKey: fetchSucceededKey)
        }
    }

    static var hasPersistedSuccessfulFetch: Bool {
        UserDefaults.standard.bool(forKey: fetchSucceededKey)
    }

    static func readPersistedPresentationType(defaultValue: Int = 1) -> Int {
        guard let raw = UserDefaults.standard.object(forKey: presentationTypeKey) else { return defaultValue }
        guard let n = raw as? Int else { return defaultValue }
        return (n == 1 || n == 2) ? n : defaultValue
    }

    static func persistSuccessfulPresentationType(_ value: Int) {
        guard value == 1 || value == 2 else { return }
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: presentationTypeKey)
        defaults.set(true, forKey: fetchSucceededKey)
    }
}

enum VlRemoteFeatureConfigAPI {
    /// 拉取 app 配置（GetAppConfigReq）：A/B 面与 B 面充值分支均由 `type` 控制。
    static func fetchAppConfig(request: AppConfigRequest) async -> Result<AppConfigResponse, AppError> {
        await VlHTTPGatewayActor.shared.request(
            "/v1/app_config",
            method: .get,
            parameters: request.toRequestParameters(),
            requiresAuth: false
        )
    }
}
