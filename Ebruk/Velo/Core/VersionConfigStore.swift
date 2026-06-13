//
//  VersionConfigStore.swift
//  Velo
//
//  充值呈现由 `GET /v1/app_config` 控制（GetAppConfigReq：dev_id/source/channel/version/af_attribution_json）。
//  - 已成功拉取并持久化过：后续冷启动直接读本地，不再请求。
//  - 首次 / 从未成功：先 AF 归因，再请求 app_config；失败则默认 type=1 且不写入本地。
//  `type == 1` → 直链 StoreKit；`type == 2` → 支付选择 Sheet。
//

import Foundation
import SwiftUI

@MainActor
final class VersionConfigStore: ObservableObject {
    /// 与 `/v1/app_config` 的 `type` 一致；**1** 直链 IAP；**2** 支付 Sheet。
    @Published private(set) var rechargePresentationType: Int

    private static let lastRemoteRefreshKey = AppConfigPersistence.lastRemoteRefreshKey

    private var bootstrapInFlight: Task<Void, Never>?
    private var remoteRefreshInFlight: Task<Void, Never>?

    #if DEBUG
    /// DEBUG 面板手动切换后，避免远端 type 覆盖本地调试值
    private var debugTypeOverrideActive = false
    #endif

    init() {
        AppConfigPersistence.migrateLegacyKeysIfNeeded()
        if AppConfigPersistence.hasPersistedSuccessfulFetch {
            _rechargePresentationType = Published(initialValue: AppConfigPersistence.readPersistedPresentationType())
        } else {
            _rechargePresentationType = Published(initialValue: 1)
        }
    }

    private static var hasPersistedSuccessfulFetch: Bool {
        AppConfigPersistence.hasPersistedSuccessfulFetch
    }

    private static func readPersistedPresentationType() -> Int {
        AppConfigPersistence.readPersistedPresentationType()
    }

    private func persistSuccessfulPresentationType(_ value: Int) {
        AppConfigPersistence.persistSuccessfulPresentationType(value)
    }

    var usesDirectIAPRecharge: Bool {
        rechargePresentationType == 1
    }

    func bootstrapOnColdStart() async {
        if Self.hasPersistedSuccessfulFetch {
            let cached = Self.readPersistedPresentationType()
            if rechargePresentationType != cached {
                rechargePresentationType = cached
            }
            print("✅ [VersionConfigStore] app_config 使用本地缓存 type=\(cached)")
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

    /// 首启未完成时走 bootstrap；已持久化时按 `minInterval` / `force` 决定是否重新拉取远端 type。
    func refreshIfNeeded(
        minInterval: TimeInterval = 300,
        force: Bool = false
    ) async {
        if !Self.hasPersistedSuccessfulFetch {
            await bootstrapOnColdStart()
            return
        }

        if !force {
            let last = UserDefaults.standard.double(forKey: Self.lastRemoteRefreshKey)
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

    func refresh() async {
        await refreshIfNeeded(force: true)
    }

    private func performFirstLaunchBootstrap() async {
        rechargePresentationType = 1
        print("📱 [VersionConfigStore] app_config 首启：默认 type=1，等待 AF 后请求")

        let channel = await AppConfig.shared.getChannel()
        let (_, rawAttribution) = await VlThirdPartyAttributionBridge.shared.prepareForFirstLaunch(channelId: channel)
        await applyAppConfigResponse(await requestAppConfig(channel: channel, attribution: rawAttribution))
    }

    private func fetchAppConfigFromNetwork() async {
        let channel = await AppConfig.shared.getChannel()
        let rawAttribution = await VlThirdPartyAttributionBridge.shared.getAttributionForLogin()
        let result = await requestAppConfig(channel: channel, attribution: rawAttribution)
        if case .success = result {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastRemoteRefreshKey)
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
        return await VlRemoteFeatureConfigAPI.fetchAppConfig(request: request)
    }

    private func applyAppConfigResponse(_ result: Result<AppConfigResponse, AppError>) async {
        switch result {
        case .success(let resp):
            if let t = resp.type, t == 1 || t == 2 {
                #if DEBUG
                if debugTypeOverrideActive {
                    print("ℹ️ [VersionConfigStore] app_config type=\(t) ignored (DEBUG override active, keep \(rechargePresentationType))")
                    return
                }
                #endif
                rechargePresentationType = t
                persistSuccessfulPresentationType(t)
                print("✅ [VersionConfigStore] app_config 成功 type=\(t)，已持久化")
            } else if !Self.hasPersistedSuccessfulFetch {
                applyFirstLaunchFailure(reason: "invalid_type")
            }
        case .failure(let error):
            if !Self.hasPersistedSuccessfulFetch {
                applyFirstLaunchFailure(reason: error.userMessage)
            } else {
                print("⚠️ [VersionConfigStore] app_config 刷新失败(\(error.userMessage))，保留本地 type=\(rechargePresentationType)")
            }
        }
    }

    private func applyFirstLaunchFailure(reason: String) {
        rechargePresentationType = 1
        print("❌ [VersionConfigStore] app_config 首启失败(\(reason))，默认 type=1 且不保存")
    }

    #if DEBUG
    /// 覆盖远端 `type`（1 / 2）并写入与成功拉取时相同的持久化键，供 DEBUG 面板切换充值分支。
    func debugSetPresentationType(_ raw: Int) {
        let v = (raw == 1 || raw == 2) ? raw : 1
        debugTypeOverrideActive = true
        rechargePresentationType = v
        persistSuccessfulPresentationType(v)
        objectWillChange.send()
    }
    #endif
}
