import Foundation
import Combine

/// A/B/C 面由 `GET /v1/app_config` 控制（GetAppConfigReq）。
/// - **1** A 面 · **2** C 面（WebView） · **3** B 面（Velo 原生）
/// - 已成功拉取并持久化过：后续冷启动直接读本地，不再阻塞首屏。
/// - 首次 / 从未成功：先 AF 归因，再请求 app_config；失败则进 A 面且不写入本地。
@MainActor
final class AppSurfaceController: ObservableObject {
    static let shared = AppSurfaceController()

    private let requiredTaps = 7
    private let tapWindowSeconds: TimeInterval = 2

    @Published private(set) var activeSurface: AppSurfaceKind
    @Published private(set) var isBootstrapComplete: Bool
    @Published private(set) var surfaceWebURL: URL?

    /// 兼容旧逻辑：B 面 Velo 原生壳
    var isSurfaceB: Bool { activeSurface == .b }
    var isSurfaceC: Bool { activeSurface == .c }

    private var secretTapCount = 0
    private var resetTask: Task<Void, Never>?
    private var bootstrapInFlight: Task<Void, Never>?
    private var remoteRefreshInFlight: Task<Void, Never>?

    private init() {
        AppConfigPersistence.migrateLegacyKeysIfNeeded()
        if AppConfigPersistence.hasPersistedSuccessfulFetch {
            let cachedType = AppConfigPersistence.readPersistedPresentationType()
            _activeSurface = Published(initialValue: AppSurfaceKind.from(appConfigType: cachedType) ?? .a)
            _surfaceWebURL = Published(initialValue: SurfaceCConfig.resolveURL(
                remoteURLString: AppConfigPersistence.readPersistedSurfaceWebURL()
            ))
            _isBootstrapComplete = Published(initialValue: true)
        } else {
            _activeSurface = Published(initialValue: .a)
            _surfaceWebURL = Published(initialValue: nil)
            _isBootstrapComplete = Published(initialValue: false)
        }
    }

    /// 冷启动时请求 `/v1/app_config`：`type` 1/2/3 → A/C/B 面；失败默认 A 面。
    func bootstrapFromRemote() async {
        if AppConfigPersistence.hasPersistedSuccessfulFetch {
            let cached = AppConfigPersistence.readPersistedPresentationType()
            let kind = AppSurfaceKind.from(appConfigType: cached) ?? .a
            if activeSurface != kind { activeSurface = kind }
            surfaceWebURL = SurfaceCConfig.resolveURL(
                remoteURLString: AppConfigPersistence.readPersistedSurfaceWebURL()
            )
            if !isBootstrapComplete { isBootstrapComplete = true }
            print("✅ [AppSurfaceController] app_config 使用本地缓存 type=\(cached) → \(kind.logLabel)")
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

    /// Release 隐蔽手势：A ↔ B（Velo）；C 面由服务端 `type=2` 下发。
    func toggleSurface() {
        let next: AppSurfaceKind = activeSurface == .a ? .b : .a
        applySurface(next, webURLString: nil, fromManualToggle: true)
    }

    #if DEBUG
    /// Debug：A → C → B → A（对应 type 1 → 2 → 3 → 1）。
    func cycleSurfaceForDebug() {
        let next: AppSurfaceKind
        switch activeSurface {
        case .a: next = .c
        case .c: next = .b
        case .b: next = .a
        }
        applySurface(next, webURLString: nil, fromManualToggle: true)
        if next == .c {
            surfaceWebURL = SurfaceCConfig.resolveURL(
                remoteURLString: AppConfigPersistence.readPersistedSurfaceWebURL()
            )
        }
    }
    #endif

    func showSurfaceA() {
        applySurface(.a, webURLString: nil, fromManualToggle: true)
    }

    private func performFirstLaunchBootstrap() async {
        activeSurface = .a
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
            if let t = resp.type, let kind = AppSurfaceKind.from(appConfigType: t) {
                let webURLString = resp.preferredWebURLString
                applySurface(kind, webURLString: webURLString, fromManualToggle: false)
                print("✅ [AppSurfaceController] app_config 成功 type=\(t) → \(kind.logLabel)，已持久化")
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
        activeSurface = .a
        surfaceWebURL = nil
        print("❌ [AppSurfaceController] app_config 首启失败(\(reason))，进 A 面且不保存")
    }

    private func applySurface(_ kind: AppSurfaceKind, webURLString: String?, fromManualToggle: Bool) {
        activeSurface = kind
        if kind == .c {
            surfaceWebURL = SurfaceCConfig.resolveURL(remoteURLString: webURLString)
        } else {
            surfaceWebURL = nil
        }

        let configType = kind.appConfigType
        if fromManualToggle {
            AppConfigPersistence.persistSuccessfulPresentationType(configType, webURL: webURLString)
            print("ℹ️ [AppSurfaceController] 手动切换 → \(kind.logLabel)，type=\(configType) 已持久化")
        } else {
            AppConfigPersistence.persistSuccessfulPresentationType(configType, webURL: webURLString)
        }
    }

    /// 与 `VersionConfigStore.debugSetPresentationType` / 远端 `app_config.type` 对齐 A/C/B 面状态。
    func applyPresentationType(_ type: Int) {
        guard let kind = AppSurfaceKind.from(appConfigType: type) else { return }
        applySurface(kind, webURLString: AppConfigPersistence.readPersistedSurfaceWebURL(), fromManualToggle: true)
    }
}
