import Foundation

@Observable
@MainActor
final class RecipeListViewModel {
    private(set) var recipes: [Recipe] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMore = false
    private(set) var totalCount = 0
    private(set) var errorMessage: String?

    private var currentPage = 0
    private var loadTask: Task<Void, Never>?
    private var lastCategory: RecipeCategory?
    private var lastSearchQuery = ""
    private let service = RecipeAPIService.shared

    var isEmpty: Bool {
        !isLoading && recipes.isEmpty && errorMessage == nil
    }

    var loadedSummary: String {
        if isLoading && recipes.isEmpty {
            return FormulaL10n.string("content.loading")
        }
        return FormulaL10n.format("content.loaded_summary", recipes.count, totalCount)
    }

    /// 仅在筛选条件变化或尚无数据时请求，从详情返回不重复加载
    func loadIfNeeded(category: RecipeCategory?, searchQuery: String) {
        let normalizedSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recipes.isEmpty,
           lastCategory == category,
           lastSearchQuery == normalizedSearch,
           errorMessage == nil {
            return
        }
        reload(category: category, searchQuery: searchQuery)
    }

    func reload(category: RecipeCategory?, searchQuery: String) {
        loadTask?.cancel()
        loadTask = Task {
            await performReload(category: category, searchQuery: searchQuery)
        }
    }

    func refresh(category: RecipeCategory?, searchQuery: String) async {
        loadTask?.cancel()
        await performReload(category: category, searchQuery: searchQuery)
    }

    func loadMoreIfNeeded(
        currentItem: Recipe,
        category: RecipeCategory?,
        searchQuery: String
    ) {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        guard currentItem.id == recipes.last?.id else { return }

        loadTask?.cancel()
        loadTask = Task {
            await performLoadMore(category: category, searchQuery: searchQuery)
        }
    }

    private func performReload(
        category: RecipeCategory?,
        searchQuery: String
    ) async {
        isLoading = true
        isLoadingMore = false
        errorMessage = nil
        currentPage = 0
        recipes = []
        hasMore = false
        totalCount = 0

        defer { isLoading = false }

        do {
            let response = try await service.fetchRecipes(
                page: 1,
                category: category,
                searchQuery: searchQuery
            )
            guard !Task.isCancelled else { return }

            recipes = response.items
            currentPage = response.page
            totalCount = response.total
            hasMore = response.hasMore
            lastCategory = category
            lastSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FormulaL10n.string("content.load_error_retry")
            hasMore = false
        }
    }

    private func performLoadMore(
        category: RecipeCategory?,
        searchQuery: String
    ) async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let response = try await service.fetchRecipes(
                page: nextPage,
                category: category,
                searchQuery: searchQuery
            )
            guard !Task.isCancelled else { return }

            recipes.append(contentsOf: response.items)
            currentPage = response.page
            totalCount = response.total
            hasMore = response.hasMore
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FormulaL10n.string("content.load_more_error")
        }
    }
}
