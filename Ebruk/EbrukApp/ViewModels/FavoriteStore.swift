import Foundation

@Observable
@MainActor
final class FavoriteStore {
    private var favoriteIDs: [Int]
    private let storageKey = "diy_formula_favorites"

    init() {
        favoriteIDs = UserDefaults.standard.array(forKey: storageKey) as? [Int] ?? []
    }

    func isFavorite(_ recipe: Recipe) -> Bool {
        favoriteIDs.contains(recipe.id)
    }

    func toggle(_ recipe: Recipe) {
        if let index = favoriteIDs.firstIndex(of: recipe.id) {
            favoriteIDs.remove(at: index)
        } else {
            favoriteIDs.insert(recipe.id, at: 0)
        }
        persist()
    }

    func remove(_ recipe: Recipe) {
        favoriteIDs.removeAll { $0 == recipe.id }
        persist()
    }

    func favoriteRecipes(customRecipes: [Recipe]) -> [Recipe] {
        let catalog = RecipeCatalog.allRecipes(customRecipes: customRecipes)
        return favoriteIDs.compactMap { id in
            catalog.first { $0.id == id }
        }
    }

    var count: Int {
        favoriteIDs.count
    }

    func clearAll() {
        favoriteIDs.removeAll()
        persist()
    }

    func removeAll(withIDs ids: Set<Int>) {
        guard !ids.isEmpty else { return }
        favoriteIDs.removeAll { ids.contains($0) }
        persist()
    }

    func exportIDs() -> [Int] {
        favoriteIDs
    }

    func importIDs(_ ids: [Int]) {
        favoriteIDs = ids
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(favoriteIDs, forKey: storageKey)
    }
}
