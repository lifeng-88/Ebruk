//
//  AuthSessionStore.swift
//  Velo
//
//  登录态：Token 与会话标识存 Keychain；冷启动经 `VlIdentitySessionRepository` 恢复或设备登录。
//  Token 刷新由 VlHTTPGatewayActor 401 → TokenManager → `refreshToken` 完成。
//

import SwiftUI

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var userId: String?
    @Published var isLoading = false
    @Published var lastError: String?

    /// 冷启动会话是否已解析（成功或失败都会置为 true）
    @Published private(set) var launchSessionResolved = false
    /// 正在执行 `ensureAuthenticatedOnLaunch`（可选用于遮罩）
    @Published private(set) var isResolvingLaunchAuth = false

    private let defaults = UserDefaults.standard

    private enum LegacyDefaultsKey {
        static let loggedIn = "velo.auth.loggedIn"
        static let userId = "velo.auth.userId"
        static let accessToken = "velo.auth.accessToken"
        static let refreshToken = "velo.auth.refreshToken"
    }

    init() {
        isAuthenticated = defaults.bool(forKey: LegacyDefaultsKey.loggedIn)
        userId = defaults.string(forKey: LegacyDefaultsKey.userId)
    }

    var displayUserId: String {
        userId ?? "—"
    }

    /// 应用启动时调用：迁移旧 UserDefaults → Keychain，再经协议恢复会话或设备登录。
    func performLaunchAuthentication(repository: VlIdentitySessionRepositoryProtocol = VlIdentitySessionRepository.shared) async {
        isResolvingLaunchAuth = true
        lastError = nil
        defer {
            isResolvingLaunchAuth = false
            launchSessionResolved = true
        }

        await migrateLegacySessionToKeychainIfNeeded(repository: repository)
        await restoreSessionFlagsFromKeychain()

        let result = await repository.ensureAuthenticatedOnLaunch()
        switch result {
        case .success(let info):
            await applyAuthenticatedSession(info)
        case .failure(let error):
            lastError = error.userMessage
            if await repository.getCurrentAuthInfo() == nil {
                await clearLocalSession(repository: repository)
            } else if let info = await repository.getCurrentAuthInfo() {
                await applyAuthenticatedSession(info)
            }
        }
    }

    private func migrateLegacySessionToKeychainIfNeeded(repository: VlIdentitySessionRepositoryProtocol) async {
        if await repository.getCurrentAuthInfo() != nil { return }

        guard let access = defaults.string(forKey: LegacyDefaultsKey.accessToken),
              let refresh = defaults.string(forKey: LegacyDefaultsKey.refreshToken),
              let uid = defaults.string(forKey: LegacyDefaultsKey.userId),
              !access.isEmpty, !refresh.isEmpty else {
            return
        }

        let info = AuthInfo(userid: uid, accessToken: access, refreshToken: refresh)
        do {
            try await repository.saveAuthInfo(info)
            removeLegacyAuthDefaults()
            print("✅ [AuthSessionStore] 已将旧版 Token 从 UserDefaults 迁移到 Keychain")
        } catch {
            print("⚠️ [AuthSessionStore] 迁移 token 到 Keychain 失败: \(error)")
        }
    }

    private func restoreSessionFlagsFromKeychain() async {
        let session = await VeloUserKeychainStore.shared.loadSession()
        if session.loggedIn {
            isAuthenticated = true
            userId = session.userId ?? userId
            return
        }

        if isAuthenticated || userId != nil {
            isAuthenticated = defaults.bool(forKey: LegacyDefaultsKey.loggedIn)
            userId = defaults.string(forKey: LegacyDefaultsKey.userId)
            if isAuthenticated {
                do {
                    try await VeloUserKeychainStore.shared.saveSession(loggedIn: true, userId: userId)
                    removeLegacyAuthDefaults()
                } catch {
                    print("⚠️ [AuthSessionStore] 迁移登录态到 Keychain 失败: \(error)")
                }
            }
        }
    }

    func loginWithDevice(repository: VlIdentitySessionRepositoryProtocol = VlIdentitySessionRepository.shared) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let result = await AuthReloginHelper.login(with: await VlThirdPartyAttributionBridge.shared.getAttributionForLogin())

        switch result {
        case .success(let info):
            await applyAuthenticatedSession(info)
        case .failure(let err):
            lastError = err.userMessage
        }
    }

    func logout() {
        userId = nil
        isAuthenticated = false
        lastError = nil
        Task {
            await VlIdentitySessionRepository.shared.logout()
            await VeloUserKeychainStore.shared.clearSession()
            removeLegacyAuthDefaults()
        }
    }

    /// 刷新或静默重登后同步 Keychain 到 UI 层
    func applySessionFromAuthInfo(_ info: AuthInfo) {
        Task {
            await applyAuthenticatedSession(info)
        }
    }

    private func applyAuthenticatedSession(_ info: AuthInfo) async {
        isAuthenticated = true
        userId = info.userid
        lastError = nil
        do {
            try await VeloUserKeychainStore.shared.saveSession(loggedIn: true, userId: info.userid)
            removeLegacyAuthDefaults()
        } catch {
            print("⚠️ [AuthSessionStore] 保存登录态到 Keychain 失败: \(error)")
        }
    }

    private func clearLocalSession(repository: VlIdentitySessionRepositoryProtocol) async {
        isAuthenticated = false
        userId = nil
        await VeloUserKeychainStore.shared.clearSession()
        removeLegacyAuthDefaults()
    }

    private func removeLegacyAuthDefaults() {
        defaults.removeObject(forKey: LegacyDefaultsKey.loggedIn)
        defaults.removeObject(forKey: LegacyDefaultsKey.userId)
        defaults.removeObject(forKey: LegacyDefaultsKey.accessToken)
        defaults.removeObject(forKey: LegacyDefaultsKey.refreshToken)
    }

    #if DEBUG
    /// DEBUG：调用服务端登出、清空 Keychain、清除本地媒体/模板/充值缓存，并重置 UI 登录态（不自动重新登录）。
    func debugLogoutAndClearLocalData() async {
        _ = await VlIdentitySessionRepository.shared.logout()
        await KeychainManager.shared.clearAll()
        await VeloUserKeychainStore.shared.clearAllUserData()
        removeLegacyAuthDefaults()

        userId = nil
        isAuthenticated = false
        lastError = nil

        await MediaCacheMaintenance.clearAllMediaFileCaches()
        VlCatalogMaterialDiskCache.shared.clearAllCache()
        VlPurchaseMaterialDiskCache.shared.clearAllCache()
        URLCache.shared.removeAllCachedResponses()

        print("🧹 [AuthSessionStore] DEBUG 退出登录：Keychain 与本地缓存已清除")
    }
    #endif
}

extension Notification.Name {
    static let veloAuthSessionDidUpdate = Notification.Name("velo.auth.sessionDidUpdate")
}
