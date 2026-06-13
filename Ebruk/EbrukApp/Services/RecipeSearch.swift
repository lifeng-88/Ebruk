import Foundation

enum RecipeSearch {
    static func matches(_ recipe: Recipe, query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return true }

        let localized = recipe.localized
        let categoryNames = [
            recipe.category.rawValue.lowercased(),
            recipe.category.localizedName.lowercased()
        ]

        return recipe.name.lowercased().contains(normalized)
            || localized.name.lowercased().contains(normalized)
            || recipe.materials.joined(separator: " ").lowercased().contains(normalized)
            || localized.materials.joined(separator: " ").lowercased().contains(normalized)
            || categoryNames.contains { $0.contains(normalized) }
    }
}
