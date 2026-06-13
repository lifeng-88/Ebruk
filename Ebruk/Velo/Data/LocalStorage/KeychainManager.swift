//
//  KeychainManager.swift
//  Velo
//
//  Created by Dev on 2026/1/18.
//

import Foundation
import Security

/// Keychain 管理器 - 用于安全存储敏感数据（Token、用户会话、钱包等）
actor KeychainManager {
    static let shared = KeychainManager()
    
    private let service: String
    
    private init() {
        self.service = Bundle.main.bundleIdentifier ?? "com.ebruk.app"
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }
    
    /// 保存字符串到 Keychain
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AppError.storageError("Failed to convert string to data")
        }
        try saveData(key: key, data: data)
    }

    /// 保存二进制数据到 Keychain
    func saveData(key: String, data: Data) throws {
        delete(key: key)

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.storageError("Failed to save to keychain: \(status)")
        }
    }
    
    /// 从 Keychain 读取字符串
    func load(key: String) -> String? {
        guard let data = loadData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 从 Keychain 读取二进制数据
    func loadData(key: String) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }
    
    /// 从 Keychain 删除数据
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    /// 清空当前 App 在 Keychain 中的全部数据
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
