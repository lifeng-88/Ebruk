import Foundation

struct RecipePageResponse {
    let items: [Recipe]
    let page: Int
    let pageSize: Int
    let total: Int

    var hasMore: Bool {
        page * pageSize < total
    }
}

final class RecipeAPIService {
    static let shared = RecipeAPIService()
    static let pageSize = 20

    private init() {}

    /// 模拟网络请求，每页返回 20 条内置配方
    func fetchRecipes(
        page: Int,
        category: RecipeCategory?,
        searchQuery: String
    ) async throws -> RecipePageResponse {
        let delay = UInt64.random(in: 600_000_000...1_000_000_000)
        try await Task.sleep(nanoseconds: delay)
        try Task.checkCancellation()

        let filtered = filterRecipes(category: category, searchQuery: searchQuery)
        let total = filtered.count
        let start = max(0, (page - 1) * Self.pageSize)

        guard start < total else {
            return RecipePageResponse(
                items: [],
                page: page,
                pageSize: Self.pageSize,
                total: total
            )
        }

        let end = min(start + Self.pageSize, total)
        let items = Array(filtered[start..<end])

        return RecipePageResponse(
            items: items,
            page: page,
            pageSize: Self.pageSize,
            total: total
        )
    }

    private func filterRecipes(
        category: RecipeCategory?,
        searchQuery: String
    ) -> [Recipe] {
        var result = RecipeStore.all

        if let category {
            result = result.filter { $0.category == category }
        }

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { RecipeSearch.matches($0, query: query) }
        }

        if category == nil {
            result.sort { lhs, rhs in
                lhs.localized.name.localizedStandardCompare(rhs.localized.name) == .orderedAscending
            }
        }

        return result
    }
}
