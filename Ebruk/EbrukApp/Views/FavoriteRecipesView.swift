import SwiftUI

struct FavoriteRecipesView: View {
    @Environment(FavoriteStore.self) private var favoriteStore
    @Environment(CustomRecipeStore.self) private var customRecipeStore
    @Environment(CoinStore.self) private var coinStore

    @State private var searchText = ""
    @State private var recipeToUnlock: Recipe?
    @State private var recipeToView: Recipe?
    @State private var isSelecting = false
    @State private var selectedIDs = Set<Int>()
    @State private var showDeleteConfirm = false

    private var favorites: [Recipe] {
        let all = favoriteStore.favoriteRecipes(customRecipes: customRecipeStore.recipes)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return all }
        return all.filter { RecipeSearch.matches($0, query: query) }
    }

    private var isAllSelected: Bool {
        !favorites.isEmpty && selectedIDs.count == favorites.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView {
                        Label(FormulaL10n.string("favorites.empty"), systemImage: "heart")
                    } description: {
                        Text(FormulaL10n.string("favorites.empty_hint"))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favorites) { recipe in
                                favoriteRow(recipe)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .centeredNavigationTitle(FormulaL10n.string("favorites.title"))
            .searchable(text: $searchText, prompt: FormulaL10n.string("favorites.search"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !favorites.isEmpty {
                        if isSelecting {
                            Button(FormulaL10n.string("common.cancel")) {
                                exitSelectionMode()
                            }
                        } else {
                            Button(FormulaL10n.string("common.select")) {
                                isSelecting = true
                            }
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if isSelecting {
                        Button(isAllSelected ? FormulaL10n.string("common.deselect_all") : FormulaL10n.string("common.select_all")) {
                            toggleSelectAll()
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text(
                                selectedIDs.isEmpty
                                    ? FormulaL10n.string("common.delete")
                                    : FormulaL10n.format("common.delete_count", selectedIDs.count)
                            )
                        }
                        .disabled(selectedIDs.isEmpty)
                    } else {
                        CoinBalanceView(coinStore: coinStore)
                    }
                }
            }
            .sheet(item: $recipeToUnlock) { recipe in
                UnlockRecipeSheet(recipe: recipe, coinStore: coinStore) {
                    recipeToView = recipe
                }
            }
            .navigationDestination(item: $recipeToView) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .alert(FormulaL10n.string("favorites.batch_delete"), isPresented: $showDeleteConfirm) {
                Button(FormulaL10n.string("common.cancel"), role: .cancel) {}
                Button(FormulaL10n.string("common.delete"), role: .destructive) {
                    deleteSelected()
                }
            } message: {
                Text(FormulaL10n.format("favorites.delete_confirm", selectedIDs.count))
            }
            .onChange(of: searchText) { _, _ in
                selectedIDs = selectedIDs.filter { id in
                    favorites.contains { $0.id == id }
                }
                if favorites.isEmpty {
                    exitSelectionMode()
                }
            }
        }
    }

    @ViewBuilder
    private func favoriteRow(_ recipe: Recipe) -> some View {
        let isLocked = coinStore.isLocked(recipe)
        let isFree = RecipeAccessPolicy.isFree(recipe)
        let isSelected = selectedIDs.contains(recipe.id)

        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .indigo : .secondary)
            }

            Group {
                if isSelecting {
                    RecipeCardView(
                        recipe: recipe,
                        isLocked: isLocked,
                        isFree: isFree,
                        isFavorite: true,
                        isCustom: recipe.isCustom
                    )
                } else if isLocked {
                    Button {
                        recipeToUnlock = recipe
                    } label: {
                        RecipeCardView(
                            recipe: recipe,
                            isLocked: true,
                            isFree: isFree,
                            isFavorite: true,
                            isCustom: recipe.isCustom
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        recipeToView = recipe
                    } label: {
                        RecipeCardView(
                            recipe: recipe,
                            isLocked: false,
                            isFree: isFree,
                            isFavorite: true,
                            isCustom: recipe.isCustom
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelecting else { return }
            toggleSelection(recipe.id)
        }
        .opacity(isSelecting && !isSelected ? 0.85 : 1)
    }

    private func toggleSelection(_ id: Int) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func toggleSelectAll() {
        if isAllSelected {
            selectedIDs.removeAll()
        } else {
            selectedIDs = Set(favorites.map(\.id))
        }
    }

    private func deleteSelected() {
        favoriteStore.removeAll(withIDs: selectedIDs)
        exitSelectionMode()
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedIDs.removeAll()
    }
}
