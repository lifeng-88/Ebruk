import SwiftUI

struct UnlockedRecipesView: View {
    @Environment(CoinStore.self) private var coinStore
    @Environment(FavoriteStore.self) private var favoriteStore

    @State private var recipeToView: Recipe?

    private var recipes: [Recipe] {
        coinStore.unlockedRecipes()
    }

    var body: some View {
        Group {
            if recipes.isEmpty {
                ContentUnavailableView {
                    Label(FormulaL10n.string("unlocked.empty"), systemImage: "lock.open")
                } description: {
                    Text(FormulaL10n.string("unlocked.empty_hint"))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(recipes) { recipe in
                            Button {
                                recipeToView = recipe
                            } label: {
                                RecipeCardView(
                                    recipe: recipe,
                                    isLocked: false,
                                    isFree: RecipeAccessPolicy.isFree(recipe),
                                    isFavorite: favoriteStore.isFavorite(recipe),
                                    isCustom: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .centeredNavigationTitle(FormulaL10n.string("unlocked.title"))
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $recipeToView) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }
}

#Preview {
    NavigationStack {
        UnlockedRecipesView()
            .environment(CoinStore())
            .environment(FavoriteStore())
    }
}
