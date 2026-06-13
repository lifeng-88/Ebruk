import Foundation

struct CoinPackage: Identifiable, Hashable {
    let id: String
    /// 基础金币（不含赠送）
    let baseCoins: Int
    /// 额外赠送金币
    let bonusCoins: Int
    let fallbackPrice: String
    let badge: String?
    let isRecommended: Bool

    /// 实际到账金币（基础 + 赠送）
    var coins: Int { baseCoins + bonusCoins }

    var productID: String {
        "com.ebruk.app.\(id)"
    }

    var unlockableRecipeCount: Int {
        RecipeAccessPolicy.unlockableRecipeCount(for: coins)
    }

    /// 充值卡片副文案，如「约 1 条配方」「约 1–2 条配方」。
    var unlockRecipeDescription: String {
        RecipeAccessPolicy.unlockRecipeDescription(for: coins)
    }

    var bonusLabel: String? {
        guard bonusCoins > 0 else { return nil }
        return "+\(bonusCoins)"
    }

    var localizedBadge: String? {
        guard let badge else { return nil }
        switch badge {
        case "热门": return FormulaL10n.string("package.badge.popular")
        case "超值": return FormulaL10n.string("package.badge.value")
        case "尊享": return FormulaL10n.string("package.badge.premium")
        default: return badge
        }
    }

    static let all: [CoinPackage] = [
        CoinPackage(
            id: "coins_20",
            baseCoins: 20,
            bonusCoins: 0,
            fallbackPrice: "$4.99",
            badge: nil,
            isRecommended: false
        ),
        CoinPackage(
            id: "coins_40",
            baseCoins: 40,
            bonusCoins: 10,
            fallbackPrice: "$9.99",
            badge: "热门",
            isRecommended: true
        ),
        CoinPackage(
            id: "coins_80",
            baseCoins: 80,
            bonusCoins: 40,
            fallbackPrice: "$19.99",
            badge: "超值",
            isRecommended: false
        ),
        CoinPackage(
            id: "coins_200",
            baseCoins: 200,
            bonusCoins: 140,
            fallbackPrice: "$49.99",
            badge: nil,
            isRecommended: false
        ),
        CoinPackage(
            id: "coins_400",
            baseCoins: 400,
            bonusCoins: 400,
            fallbackPrice: "$99.99",
            badge: nil,
            isRecommended: false
        ),
        CoinPackage(
            id: "coins_800",
            baseCoins: 800,
            bonusCoins: 1200,
            fallbackPrice: "$199.99",
            badge: nil,
            isRecommended: false
        ),
        CoinPackage(
            id: "coins_1200",
            baseCoins: 1200,
            bonusCoins: 2400,
            fallbackPrice: "$299.99",
            badge: "尊享",
            isRecommended: false
        ),
    ]

    static func package(for productID: String) -> CoinPackage? {
        all.first { $0.productID == productID }
    }
}
