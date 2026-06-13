import Foundation

/// 内置配方的英文正文（与 `RecipeContentEN.json` 对应）
struct RecipeLocalizedContent: Codable, Hashable {
    let id: Int
    let name: String
    let materials: [String]
    let ratio: String
    let steps: String
    let safetyNote: String?
}
