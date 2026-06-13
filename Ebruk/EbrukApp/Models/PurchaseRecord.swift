import Foundation

struct PurchaseRecord: Identifiable, Codable, Hashable {
    let id: UInt64
    let productID: String
    let coins: Int
    let purchasedAt: Date
    let environment: String

    var packageName: String {
        if let package = CoinPackage.package(for: productID), package.bonusCoins > 0 {
            return "\(coins) 金币（含 \(package.bonusCoins) 赠送）"
        }
        return "\(coins) 金币"
    }
}

enum RestoreResult: Equatable {
    case restored(coins: Int, count: Int)
    case nothingToRestore
    case failed(String)
}
