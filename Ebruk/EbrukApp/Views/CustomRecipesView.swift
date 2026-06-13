import SwiftUI

struct CustomRecipesView: View {
    @Environment(CustomRecipeStore.self) private var customRecipeStore
    @Environment(FavoriteStore.self) private var favoriteStore

    @State private var searchText = ""
    @State private var showEditor = false
    @State private var recipeToEdit: Recipe?
    @State private var recipeToView: Recipe?
    @State private var isSelecting = false
    @State private var selectedIDs = Set<Int>()
    @State private var showDeleteConfirm = false

    private var filteredRecipes: [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return customRecipeStore.recipes }
        return customRecipeStore.recipes.filter {
            $0.name.lowercased().contains(query) ||
            $0.materials.joined(separator: " ").lowercased().contains(query)
        }
    }

    private var isAllSelected: Bool {
        !filteredRecipes.isEmpty && selectedIDs.count == filteredRecipes.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if customRecipeStore.recipes.isEmpty {
                    ContentUnavailableView {
                        Label(FormulaL10n.string("custom.empty"), systemImage: "square.and.pencil")
                    } description: {
                        Text(FormulaL10n.string("custom.empty_hint"))
                    } actions: {
                        Button(FormulaL10n.string("custom.create")) {
                            showEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecipes) { recipe in
                                customRow(recipe)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .centeredNavigationTitle(FormulaL10n.string("custom.title"))
            .searchable(text: $searchText, prompt: FormulaL10n.string("custom.search"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !customRecipeStore.recipes.isEmpty {
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
                        Button {
                            recipeToEdit = nil
                            showEditor = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(FormulaL10n.string("custom.create"))
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                RecipeEditorView(recipe: recipeToEdit)
            }
            .navigationDestination(item: $recipeToView) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .alert(FormulaL10n.string("custom.batch_delete"), isPresented: $showDeleteConfirm) {
                Button(FormulaL10n.string("common.cancel"), role: .cancel) {}
                Button(FormulaL10n.string("common.delete"), role: .destructive) {
                    deleteSelected()
                }
            } message: {
                Text(FormulaL10n.format("custom.delete_confirm_permanent", selectedIDs.count))
            }
            .onChange(of: searchText) { _, _ in
                selectedIDs = selectedIDs.filter { id in
                    filteredRecipes.contains { $0.id == id }
                }
                if filteredRecipes.isEmpty {
                    exitSelectionMode()
                }
            }
        }
    }

    @ViewBuilder
    private func customRow(_ recipe: Recipe) -> some View {
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
                        isLocked: false,
                        isFree: false,
                        isFavorite: favoriteStore.isFavorite(recipe),
                        isCustom: true
                    )
                } else {
                    Button {
                        recipeToView = recipe
                    } label: {
                        RecipeCardView(
                            recipe: recipe,
                            isLocked: false,
                            isFree: false,
                            isFavorite: favoriteStore.isFavorite(recipe),
                            isCustom: true
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                toggleSelection(recipe.id)
            }
        }
        .opacity(isSelecting && !isSelected ? 0.85 : 1)
        .contextMenu {
            if !isSelecting {
                Button {
                    recipeToEdit = recipe
                    showEditor = true
                } label: {
                    Label(FormulaL10n.string("detail.edit"), systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteRecipes(withIDs: [recipe.id])
                } label: {
                    Label(FormulaL10n.string("common.delete"), systemImage: "trash")
                }
            }
        }
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
            selectedIDs = Set(filteredRecipes.map(\.id))
        }
    }

    private func deleteSelected() {
        deleteRecipes(withIDs: selectedIDs)
        exitSelectionMode()
    }

    private func deleteRecipes(withIDs ids: Set<Int>) {
        favoriteStore.removeAll(withIDs: ids)
        customRecipeStore.deleteAll(withIDs: ids)
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedIDs.removeAll()
    }
}
