import Foundation

struct AppBackup: Codable {
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date
    let customRecipes: [Recipe]
    let favoriteIDs: [Int]
    let coins: Int
    let unlockedRecipeIDs: [Int]
}

enum BackupImportResult: Equatable {
    case success(customCount: Int, favoriteCount: Int, coinCount: Int, unlockedCount: Int)
    case invalidFormat
    case unsupportedVersion
    case readFailed(String)
}
