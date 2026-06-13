import Foundation

/// 内置配方多语言正文（当前支持英文）
enum RecipeLocalization {
    private static let englishByID: [Int: RecipeLocalizedContent] = loadEnglish()

    static func localized(_ recipe: Recipe) -> Recipe {
        guard !recipe.isCustom, FormulaL10n.prefersEnglishUI else { return recipe }
        guard let content = englishByID[recipe.id] else { return recipe }
        return Recipe(
            id: recipe.id,
            name: content.name,
            category: recipe.category,
            materials: content.materials,
            ratio: content.ratio,
            steps: content.steps,
            safetyNote: content.safetyNote,
            isCustom: false
        )
    }

    static func localizedRecipes(_ recipes: [Recipe]) -> [Recipe] {
        recipes.map { localized($0) }
    }

    private static func loadEnglish() -> [Int: RecipeLocalizedContent] {
        guard let url = Bundle.main.url(forResource: "RecipeContentEN", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([RecipeLocalizedContent].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }
}
