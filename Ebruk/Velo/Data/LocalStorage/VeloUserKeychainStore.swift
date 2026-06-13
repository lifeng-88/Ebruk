//
//  VeloUserKeychainStore.swift
//  Velo
//
//  B 面用户数据 Keychain 持久化：登录态标记、钱包余额、充值流水、支付卡等。
//

import Foundation

enum VeloKeychainKey {
    static let accessToken = "accessToken"
    static let refreshToken = "refreshToken"
    static let userid = "userid"
    static let devId = "velo.devId"

    static let loggedIn = "velo.session.loggedIn"
    static let sessionUserId = "velo.session.userId"
    static let walletBalance = "velo.wallet.coinBalance"
    static let walletHistory = "velo.wallet.transactionHistory"
    static let walletCards = "velo.wallet.savedCards"
}

actor VeloUserKeychainStore {
    static let shared = VeloUserKeychainStore()

    private let keychain = KeychainManager.shared

    private init() {}

    func saveSession(loggedIn: Bool, userId: String?) async throws {
        try await keychain.save(key: VeloKeychainKey.loggedIn, value: loggedIn ? "1" : "0")
        if let userId, !userId.isEmpty {
            try await keychain.save(key: VeloKeychainKey.sessionUserId, value: userId)
        } else {
            await keychain.delete(key: VeloKeychainKey.sessionUserId)
        }
    }

    func loadSession() async -> (loggedIn: Bool, userId: String?) {
        let loggedIn = (await keychain.load(key: VeloKeychainKey.loggedIn)) == "1"
        let userId = await keychain.load(key: VeloKeychainKey.sessionUserId)
        return (loggedIn, userId)
    }

    func clearSession() async {
        await keychain.delete(key: VeloKeychainKey.loggedIn)
        await keychain.delete(key: VeloKeychainKey.sessionUserId)
    }

    func saveWallet(balance: Int, historyData: Data?, cardsData: Data?) async throws {
        try await keychain.save(key: VeloKeychainKey.walletBalance, value: String(balance))
        if let historyData {
            try await keychain.saveData(key: VeloKeychainKey.walletHistory, data: historyData)
        } else {
            await keychain.delete(key: VeloKeychainKey.walletHistory)
        }
        if let cardsData {
            try await keychain.saveData(key: VeloKeychainKey.walletCards, data: cardsData)
        } else {
            await keychain.delete(key: VeloKeychainKey.walletCards)
        }
    }

    func loadWallet() async -> (balance: Int?, historyData: Data?, cardsData: Data?) {
        let balance = await keychain.load(key: VeloKeychainKey.walletBalance).flatMap(Int.init)
        let historyData = await keychain.loadData(key: VeloKeychainKey.walletHistory)
        let cardsData = await keychain.loadData(key: VeloKeychainKey.walletCards)
        return (balance, historyData, cardsData)
    }

    func clearWallet() async {
        await keychain.delete(key: VeloKeychainKey.walletBalance)
        await keychain.delete(key: VeloKeychainKey.walletHistory)
        await keychain.delete(key: VeloKeychainKey.walletCards)
    }

    func clearAllUserData() async {
        await clearSession()
        await clearWallet()
    }
}
