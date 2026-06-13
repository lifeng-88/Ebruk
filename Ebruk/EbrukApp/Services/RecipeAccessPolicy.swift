import Foundation

enum RecipeAccessPolicy {
    static let minUnlockCost = 20
    static let maxUnlockCost = 200
    static let dailyBonusAmount = 5

    /// 每个分类中 ID 最小的配方为免费
    static var freeRecipeIDs: Set<Int> {
        Set(
            RecipeCategory.allCases.compactMap { category in
                RecipeStore.all
                    .filter { $0.category == category && !$0.isCustom }
                    .min(by: { $0.id < $1.id })?
                    .id
            }
        )
    }

    static func isFree(_ recipe: Recipe) -> Bool {
        recipe.isCustom || freeRecipeIDs.contains(recipe.id)
    }

    /// 按配方难易与危险程度定价，范围 20–200 金币。
    static func unlockCost(for recipe: Recipe) -> Int {
        if isFree(recipe) { return 0 }
        return RecipeDifficultyEvaluator.unlockCost(for: recipe)
    }

    static func difficultyLabel(for recipe: Recipe) -> String {
        RecipeDifficultyEvaluator.displayName(for: recipe)
    }

    /// 用于充值页估算可解锁条数（按付费配方中位解锁成本，比均值更贴近多数配方定价）。
    static var medianPaidUnlockCost: Int {
        let costs = RecipeStore.all
            .filter { !isFree($0) }
            .map { unlockCost(for: $0) }
            .sorted()
        guard !costs.isEmpty else { return minUnlockCost }
        let mid = costs.count / 2
        if costs.count.isMultiple(of: 2) {
            return max(minUnlockCost, (costs[mid - 1] + costs[mid]) / 2)
        }
        return max(minUnlockCost, costs[mid])
    }

    /// 充值页展示：「约 X 条配方」或低档「约 X–Y 条配方」（Y 为按最低档 20 金币估算的上限）。
    static func unlockRecipeDescription(for coins: Int) -> String {
        guard coins >= minUnlockCost else {
            return FormulaL10n.string("policy.unlock_not_enough")
        }

        let typical = max(1, coins / medianPaidUnlockCost)
        let simpleTierCount = coins / minUnlockCost

        if simpleTierCount <= typical {
            return FormulaL10n.format("policy.unlock_about", typical)
        }
        if simpleTierCount <= typical + 1 {
            return FormulaL10n.format("policy.unlock_range", typical, simpleTierCount)
        }
        return FormulaL10n.format("policy.unlock_about", typical)
    }

    /// 保留数值估算（兼容旧引用）。
    static func unlockableRecipeCount(for coins: Int) -> Int {
        guard coins >= minUnlockCost else { return 0 }
        return max(1, coins / medianPaidUnlockCost)
    }

    /// 用于充值页估算可解锁条数（按付费配方平均解锁成本）。
    static var averagePaidUnlockCost: Int {
        let costs = RecipeStore.all
            .filter { !isFree($0) }
            .map { unlockCost(for: $0) }
        guard !costs.isEmpty else { return minUnlockCost }
        return max(minUnlockCost, costs.reduce(0, +) / costs.count)
    }
}
