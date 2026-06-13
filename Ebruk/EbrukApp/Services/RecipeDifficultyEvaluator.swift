import Foundation

/// 根据配方原料、步骤与安全提示评估难易与危险程度，映射解锁金币。
enum RecipeDifficultyEvaluator {
    enum Level: Int, CaseIterable, Comparable {
        case simple = 1
        case normal = 2
        case moderate = 3
        case challenging = 4
        case hazardous = 5
        case extreme = 6

        var unlockCost: Int {
            switch self {
            case .simple: 20
            case .normal: 50
            case .moderate: 80
            case .challenging: 120
            case .hazardous: 160
            case .extreme: 200
            }
        }

        var displayName: String {
            switch self {
            case .simple: FormulaL10n.string("difficulty.simple")
            case .normal: FormulaL10n.string("difficulty.normal")
            case .moderate: FormulaL10n.string("difficulty.moderate")
            case .challenging: FormulaL10n.string("difficulty.challenging")
            case .hazardous: FormulaL10n.string("difficulty.hazardous")
            case .extreme: FormulaL10n.string("difficulty.extreme")
            }
        }

        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private static let highRiskKeywords = [
        "汽油", "煤油", "松节油", "高度易燃", "强酸", "强碱", "氢氧化钠",
        "石灰", "漂白水", "腐蚀性", "有毒", "甲醛", "沥青"
    ]

    private static let mediumRiskKeywords = [
        "酒精", "易燃", "火源", "明火", "通风", "粉尘", "护目镜", "腐蚀",
        "漂白", "过氧化氢", "断电", "电源", "加热", "微沸", "隔水", "防烫"
    ]

    private static let complexStepKeywords = [
        "过滤", "研磨", "发酵", "蒸馏", "精确", "温度", "pH", "乳化", "皂化", "隔水加热"
    ]

    static func level(for recipe: Recipe) -> Level {
        let score = difficultyScore(for: recipe)
        switch score {
        case ..<26: return .simple
        case 26..<46: return .normal
        case 46..<61: return .moderate
        case 61..<76: return .challenging
        case 76..<91: return .hazardous
        default: return .extreme
        }
    }

    static func unlockCost(for recipe: Recipe) -> Int {
        level(for: recipe).unlockCost
    }

    static func displayName(for recipe: Recipe) -> String {
        level(for: recipe).displayName
    }

    private static func difficultyScore(for recipe: Recipe) -> Int {
        let materialsText = recipe.materials.joined(separator: " ")
        let content = [materialsText, recipe.steps, recipe.ratio, recipe.safetyNote ?? ""]
            .joined(separator: " ")

        var score = 0

        score += min(recipe.materials.count * 4, 20)
        score += min(recipe.steps.count / 25, 15)

        for keyword in highRiskKeywords where content.contains(keyword) {
            score += 12
        }
        for keyword in mediumRiskKeywords where content.contains(keyword) {
            score += 5
        }
        for keyword in complexStepKeywords where recipe.steps.contains(keyword) {
            score += 8
        }

        if let safetyNote = recipe.safetyNote, !safetyNote.isEmpty {
            score += 8
            if highRiskKeywords.contains(where: { safetyNote.contains($0) }) {
                score += 18
            }
        }

        if recipe.materials.count >= 5 {
            score += 6
        }

        return score
    }
}
