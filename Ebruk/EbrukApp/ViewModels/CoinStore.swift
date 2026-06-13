import Foundation

enum UnlockResult {
    case success
    case alreadyUnlocked
    case insufficientCoins
}

@Observable
@MainActor
final class CoinStore {
    private(set) var coins: Int
    private var unlockedIDs: Set<Int>

    private let coinsKey = "diy_formula_coins"
    private let unlockedKey = "diy_formula_unlocked_recipes"

    init() {
        if UserDefaults.standard.object(forKey: coinsKey) == nil {
            coins = 50
            unlockedIDs = []
            persist()
        } else {
            coins = UserDefaults.standard.integer(forKey: coinsKey)
            let saved = UserDefaults.standard.array(forKey: unlockedKey) as? [Int] ?? []
            unlockedIDs = Set(saved)
        }
    }

    func isUnlocked(_ recipe: Recipe) -> Bool {
        recipe.isCustom || RecipeAccessPolicy.isFree(recipe) || unlockedIDs.contains(recipe.id)
    }

    func isLocked(_ recipe: Recipe) -> Bool {
        !isUnlocked(recipe)
    }

    var unlockedCount: Int {
        unlockedIDs.count
    }

    func unlockedRecipes() -> [Recipe] {
        RecipeStore.all
            .filter { unlockedIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.category != rhs.category {
                    return lhs.category.rawValue < rhs.category.rawValue
                }
                return lhs.name < rhs.name
            }
    }

    func unlock(recipe: Recipe) -> UnlockResult {
        if isUnlocked(recipe) {
            return .alreadyUnlocked
        }

        let cost = RecipeAccessPolicy.unlockCost(for: recipe)
        guard coins >= cost else {
            return .insufficientCoins
        }

        coins -= cost
        unlockedIDs.insert(recipe.id)
        persist()
        return .success
    }

    func claimDailyBonus() -> Bool {
        let key = "diy_formula_daily_bonus"
        let today = dailyKey()
        guard UserDefaults.standard.string(forKey: key) != today else {
            return false
        }

        coins += RecipeAccessPolicy.dailyBonusAmount
        UserDefaults.standard.set(today, forKey: key)
        persist()
        return true
    }

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        persist()
    }

    private func dailyKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    func resetUnlocks() {
        unlockedIDs.removeAll()
        persist()
    }

    func exportCoins() -> Int {
        coins
    }

    func exportUnlockedIDs() -> [Int] {
        Array(unlockedIDs)
    }

    func importData(coins: Int, unlockedIDs: [Int]) {
        self.coins = max(0, coins)
        self.unlockedIDs = Set(unlockedIDs)
        persist()
    }

    func isDailyBonusClaimedToday() -> Bool {
        let key = "diy_formula_daily_bonus"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: .now)
        return UserDefaults.standard.string(forKey: key) == today
    }

    private func persist() {
        UserDefaults.standard.set(coins, forKey: coinsKey)
        UserDefaults.standard.set(Array(unlockedIDs), forKey: unlockedKey)
    }
}
