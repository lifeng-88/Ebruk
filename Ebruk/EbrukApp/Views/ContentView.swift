import SwiftUI

struct ContentView: View {
    @ObservedObject private var surface = AppSurfaceController.shared
    @Environment(AppSettingsStore.self) private var appSettings
    @Environment(CoinStore.self) private var coinStore
    @Environment(FavoriteStore.self) private var favoriteStore
    @Environment(RecipeListViewModel.self) private var viewModel
    @State private var searchText = ""
    @State private var selectedCategory: RecipeCategory?
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var recipeToUnlock: Recipe?
    @State private var recipeToView: Recipe?
    @State private var showCreateRecipe = false

    #if DEBUG
    private var debugSurfaceSwitchLabel: String {
        switch surface.activeSurface {
        case .a: return "C面"
        case .c: return "B面"
        case .b: return "A面"
        }
    }
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categorySection
                    recipeSection
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .centeredNavigationTitle(FormulaL10n.string("app.name"))
            .searchable(text: $searchText, prompt: FormulaL10n.string("content.search_prompt"))
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        surface.cycleSurfaceForDebug()
                    } label: {
                        Text(debugSurfaceSwitchLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                #endif
                ToolbarItem(placement: .topBarTrailing) {
                    CoinBalanceView(coinStore: coinStore)
                }
            }
            .refreshable {
                await viewModel.refresh(
                    category: selectedCategory,
                    searchQuery: searchText
                )
            }
            .task {
                viewModel.loadIfNeeded(
                    category: selectedCategory,
                    searchQuery: searchText
                )
            }
            .onChange(of: appSettings.languagePreference) { _, _ in
                viewModel.reload(
                    category: selectedCategory,
                    searchQuery: searchText
                )
            }
            .onChange(of: selectedCategory) { _, _ in
                viewModel.loadIfNeeded(
                    category: selectedCategory,
                    searchQuery: searchText
                )
            }
            .onChange(of: searchText) { _, newValue in
                searchDebounceTask?.cancel()
                searchDebounceTask = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard !Task.isCancelled else { return }
                    viewModel.loadIfNeeded(
                        category: selectedCategory,
                        searchQuery: newValue
                    )
                }
            }
            .sheet(isPresented: $showCreateRecipe) {
                RecipeEditorView(recipe: nil)
            }
            .sheet(item: $recipeToUnlock) { recipe in
                UnlockRecipeSheet(recipe: recipe, coinStore: coinStore) {
                    recipeToView = recipe
                }
            }
            .navigationDestination(item: $recipeToView) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(FormulaL10n.string("content.categories"))
                    .font(.headline)
                Spacer()
                Button {
                    showCreateRecipe = true
                } label: {
                    Label(FormulaL10n.string("content.custom_recipe"), systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.indigo)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryChip(
                        title: FormulaL10n.string("content.all"),
                        icon: "square.grid.2x2",
                        color: .indigo,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(RecipeCategory.allCases) { category in
                        CategoryChip(
                            title: category.localizedName,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage = viewModel.errorMessage, viewModel.recipes.isEmpty {
                errorView(message: errorMessage)
            } else if viewModel.isLoading && viewModel.recipes.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 40)
            } else {
                recipeList
            }
        }
    }

    private var recipeList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.recipes) { recipe in
                recipeRow(recipe)
                    .onAppear {
                        viewModel.loadMoreIfNeeded(
                            currentItem: recipe,
                            category: selectedCategory,
                            searchQuery: searchText
                        )
                    }
            }

            if viewModel.isLoadingMore {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(FormulaL10n.string("content.load_more"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if !viewModel.hasMore, !viewModel.recipes.isEmpty {
                Text(FormulaL10n.string("content.all_loaded"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func recipeRow(_ recipe: Recipe) -> some View {
        let isLocked = coinStore.isLocked(recipe)
        let isFree = RecipeAccessPolicy.isFree(recipe)

        if isLocked {
            Button {
                recipeToUnlock = recipe
            } label: {
                RecipeCardView(
                    recipe: recipe,
                    isLocked: true,
                    isFree: isFree,
                    isFavorite: favoriteStore.isFavorite(recipe),
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
                    isFavorite: favoriteStore.isFavorite(recipe),
                    isCustom: recipe.isCustom
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(FormulaL10n.string("content.loading"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(FormulaL10n.format("content.loading_page_size", RecipeAPIService.pageSize))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label(FormulaL10n.string("content.load_failed"), systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button(FormulaL10n.string("content.retry")) {
                viewModel.reload(
                    category: selectedCategory,
                    searchQuery: searchText
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 40)
    }
}

#Preview {
    ContentView()
}
