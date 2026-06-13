import Foundation

enum RecipeCatalog {
    static func allRecipes(customRecipes: [Recipe]) -> [Recipe] {
        RecipeStore.all + customRecipes
    }

    static func recipe(id: Int, customRecipes: [Recipe]) -> Recipe? {
        if let custom = customRecipes.first(where: { $0.id == id }) {
            return custom
        }
        return RecipeStore.all.first(where: { $0.id == id })
    }
}
