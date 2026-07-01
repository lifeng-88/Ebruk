import Foundation

/// C 面 H5 地址：远端 `app_config` → 本地缓存 → Info.plist `SurfaceCURL` → 默认 `lushmove.xin/h5/landing?channel=<ChannelId>`。
enum SurfaceCConfig {
    private static let infoKey = "SurfaceCURL"
    private static let defaultLandingBase = "https://lushmove.xin/h5/landing"

    static func resolveURL(remoteURLString: String?) -> URL? {
        if let url = normalizedURL(from: remoteURLString) { return url }
        if let cached = AppConfigPersistence.readPersistedSurfaceWebURL(),
           let url = normalizedURL(from: cached) {
            return url
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String,
           let url = normalizedURL(from: plist) {
            return landingURLWithConfiguredChannel(base: url)
        }
        return defaultLandingURL()
    }

    /// 默认 C 面 landing（不含 `did`）；`channel` 来自 Info.plist `AppChannel` / `ChannelId`。
    static func defaultLandingURL() -> URL? {
        guard let base = normalizedURL(from: defaultLandingBase) else { return nil }
        return landingURLWithConfiguredChannel(base: base)
    }

    /// 与 `AppConfig.getChannel()` 一致，同步读取 Info.plist 渠道配置。
    static func configuredChannelId() -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: "AppChannel") as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) {
                return trimmed
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "ChannelId") as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) {
                return trimmed
            }
        }
        return AppConfig.buildDefaultChannelId
    }

    private static func landingURLWithConfiguredChannel(base: URL) -> URL? {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            return base
        }
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "channel" }
        items.append(URLQueryItem(name: "channel", value: configuredChannelId()))
        components.queryItems = items
        return components.url ?? base
    }

    private static func normalizedURL(from raw: String?) -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) else { return nil }
        return URL(string: trimmed)
    }
}
