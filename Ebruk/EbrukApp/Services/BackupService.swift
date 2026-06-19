import Foundation

enum BackupService {
    static func makeBackup(
        customRecipes: [Recipe],
        favoriteIDs: [Int],
        coins: Int,
        unlockedRecipeIDs: [Int]
    ) -> AppBackup {
        AppBackup(
            version: AppBackup.currentVersion,
            exportedAt: .now,
            customRecipes: customRecipes,
            favoriteIDs: favoriteIDs,
            coins: coins,
            unlockedRecipeIDs: unlockedRecipeIDs
        )
    }

    static func exportURL(from backup: AppBackup) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "Ebruk_Backup_\(formatter.string(from: backup.exportedAt)).json"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func parseBackup(from url: URL) -> BackupImportResult {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(AppBackup.self, from: data)

            guard backup.version <= AppBackup.currentVersion else {
                return .unsupportedVersion
            }

            return .success(
                customCount: backup.customRecipes.count,
                favoriteCount: backup.favoriteIDs.count,
                coinCount: backup.coins,
                unlockedCount: backup.unlockedRecipeIDs.count
            )
        } catch is DecodingError {
            return .invalidFormat
        } catch {
            return .readFailed(error.localizedDescription)
        }
    }

    static func loadBackup(from url: URL) throws -> AppBackup {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppBackup.self, from: data)
    }
}
