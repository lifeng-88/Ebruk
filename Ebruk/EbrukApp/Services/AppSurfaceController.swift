import Foundation
import Combine

/// A/B 面由 `GET /v1/app_config` 控制（GetAppConfigReq），与 ReelMix `VersionConfigStore` 一致。
/// - 已成功拉取并持久化过：后续冷启动直接读本地，不再阻塞首屏。
/// - 首次 / 从未成功：先 AF 归因，再请求 app_config；失败则进 A 面且不写入本地。
@MainActor
final class AppSurfaceController: ObservableObject {
    static let shared = AppSurfaceController()

    private let requiredTaps = 7
    private let tapWindowSeconds: TimeInterval = 2

    @Published private(set) var isSurfaceB: Bool
    @Published private(set) var isBootstrapComplete: Bool

    private var secretTapCount = 0
    private var resetTask: Task<Void, Never>?
    private var bootstrapInFlight: Task<Void, Never>?
    private var remoteRefreshInFlight: Task<Void, Never>?

    private init() {
        AppConfigPersistence.migrateLegacyKeysIfNeeded()
        if AppConfigPersistence.hasPersistedSuccessfulFetch {
            _isSurfaceB = Published(initialValue: AppConfigPersistence.readPersistedPresentationType() == 2)
            _isBootstrapComplete = Published(initialValue: true)
        } else {
            _isSurfaceB = Published(initialValue: false)
            _isBootstrapComplete = Published(initialValue: false)
        }
    }

    /// 冷启动时请求 `/v1/app_config`：`type == 2` 进 B 面，否则进 A 面；失败默认 A 面。
    func bootstrapFromRemote() async {
        if AppConfigPersistence.hasPersistedSuccessfulFetch {
            let cached = AppConfigPersistence.readPersistedPresentationType()
            let showB = cached == 2
            if isSurfaceB != showB { isSurfaceB = showB }
            if !isBootstrapComplete { isBootstrapComplete = true }
            print("✅ [AppSurfaceController] app_config 使用本地缓存 type=\(cached) → \(showB ? "B面" : "A面")")
            Task(priority: .utility) { await self.refreshIfNeeded() }
            return
        }

        if let inFlight = bootstrapInFlight {
            await inFlight.value
            return
        }

        let task = Task { await self.performFirstLaunchBootstrap() }
        bootstrapInFlight = task
        await task.value
        bootstrapInFlight = nil
    }

    func refreshIfNeeded(minInterval: TimeInterval = 300, force: Bool = false) async {
        if !AppConfigPersistence.hasPersistedSuccessfulFetch {
            await bootstrapFromRemote()
            return
        }

        if !force {
            let last = UserDefaults.standard.double(forKey: AppConfigPersistence.lastRemoteRefreshKey)
            guard last <= 0 || Date().timeIntervalSince1970 - last >= minInterval else { return }
        }

        if let inFlight = remoteRefreshInFlight {
            await inFlight.value
            return
        }

        let task = Task { await self.fetchAppConfigFromNetwork() }
        remoteRefreshInFlight = task
        await task.value
        remoteRefreshInFlight = nil
    }

    func registerSecretTap() {
        secretTapCount += 1
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(tapWindowSeconds * 1_000_000_000))
            secretTapCount = 0
        }
        guard secretTapCount >= requiredTaps else { return }
        secretTapCount = 0
        resetTask?.cancel()
        toggleSurface()
    }

    func toggleSurface() {
        setSurfaceB(!isSurfaceB, fromManualToggle: true)
    }

    func showSurfaceA() {
        setSurfaceB(false, fromManualToggle: true)
    }

    private func performFirstLaunchBootstrap() async {
        isSurfaceB = false
        print("📱 [AppSurfaceController] app_config 首启：默认 A 面，等待 AF 后请求")

        let channel = await AppConfig.shared.getChannel()
        let (_, rawAttribution) = await VlThirdPartyAttributionBridge.shared.prepareForFirstLaunch(channelId: channel)
        await applyAppConfigResponse(await requestAppConfig(channel: channel, attribution: rawAttribution))
        isBootstrapComplete = true
    }

    private func fetchAppConfigFromNetwork() async {
        let channel = await AppConfig.shared.getChannel()
        let rawAttribution = await VlThirdPartyAttributionBridge.shared.getAttributionForLogin()
        let result = await requestAppConfig(channel: channel, attribution: rawAttribution)
        if case .success = result {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AppConfigPersistence.lastRemoteRefreshKey)
        }
        await applyAppConfigResponse(result)
    }

    private func requestAppConfig(
        channel: String,
        attribution raw: AFAttributionResult?
    ) async -> Result<AppConfigResponse, AppError> {
        let attribution = raw ?? AFAttributionResult.timeoutFallback()
        let deviceId = await DeviceManager.shared.getDeviceId()
        let version = await DeviceManager.shared.getAppVersion()
        let request = AppConfigRequest(
            devId: deviceId,
            source: attribution.source,
            channel: channel,
            version: version,
            afAttributionJson: attribution.attributionJson
        )
        print("📱 [AppSurfaceController] 请求 /v1/app_config channel=\(channel) version=\(version)")
        return await VlRemoteFeatureConfigAPI.fetchAppConfig(request: request)
    }

    private func applyAppConfigResponse(_ result: Result<AppConfigResponse, AppError>) async {
        switch result {
        case .success(let resp):
            if let t = resp.type, t == 1 || t == 2 {
                isSurfaceB = t == 2
                AppConfigPersistence.persistSuccessfulPresentationType(t)
                print("✅ [AppSurfaceController] app_config 成功 type=\(t) → \(t == 2 ? "B面" : "A面")，已持久化")
            } else if !AppConfigPersistence.hasPersistedSuccessfulFetch {
                applyFirstLaunchFailure(reason: "invalid_type")
            }
        case .failure(let error):
            if !AppConfigPersistence.hasPersistedSuccessfulFetch {
                applyFirstLaunchFailure(reason: error.userMessage)
            } else {
                print("⚠️ [AppSurfaceController] app_config 刷新失败(\(error.userMessage))，保留本地 type=\(AppConfigPersistence.readPersistedPresentationType())")
            }
        }
    }

    private func applyFirstLaunchFailure(reason: String) {
        isSurfaceB = false
        print("❌ [AppSurfaceController] app_config 首启失败(\(reason))，进 A 面且不保存")
    }

    private func setSurfaceB(_ enabled: Bool, fromManualToggle: Bool = false) {
        isSurfaceB = enabled
        if fromManualToggle {
            print("ℹ️ [AppSurfaceController] 手动切换 → \(enabled ? "B面" : "A面")")
        }
    }
}
