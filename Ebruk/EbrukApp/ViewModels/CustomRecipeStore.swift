import Foundation

@Observable
@MainActor
final class CustomRecipeStore {
    private(set) var recipes: [Recipe] = []
    private let storageKey = "diy_formula_custom_recipes"

    init() {
        load()
    }

    @discardableResult
    func add(
        name: String,
        category: RecipeCategory,
        materials: [String],
        ratio: String,
        steps: String,
        safetyNote: String?
    ) -> Recipe {
        let newID = (recipes.map(\.id).min() ?? 0) - 1
        let recipe = Recipe(
            id: newID,
            name: name,
            category: category,
            materials: materials,
            ratio: ratio,
            steps: steps,
            safetyNote: safetyNote?.isEmpty == true ? nil : safetyNote,
            isCustom: true
        )
        recipes.insert(recipe, at: 0)
        save()
        return recipe
    }

    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe
        save()
    }

    func delete(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        save()
    }

    func deleteAll(withIDs ids: Set<Int>) {
        guard !ids.isEmpty else { return }
        recipes.removeAll { ids.contains($0.id) }
        save()
    }

    func deleteAll() {
        recipes.removeAll()
        save()
    }

    func importRecipes(_ imported: [Recipe]) {
        recipes = imported.filter(\.isCustom)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Recipe].self, from: data) else {
            return
        }
        recipes = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(recipes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
