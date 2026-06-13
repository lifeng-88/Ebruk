import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @Environment(CoinStore.self) private var coinStore
    @Environment(FavoriteStore.self) private var favoriteStore
    @Environment(CustomRecipeStore.self) private var customRecipeStore

    @State private var backupDocument: BackupFileDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImportURL: URL?
    @State private var pendingImportSummary: String?
    @State private var showImportConfirm = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        List {
            Section {
                Button {
                    exportBackup()
                } label: {
                    Label(FormulaL10n.string("backup.export"), systemImage: "square.and.arrow.up")
                }

                Button {
                    showImporter = true
                } label: {
                    Label(FormulaL10n.string("backup.import"), systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text(FormulaL10n.string("backup.footer"))
            }

            Section(FormulaL10n.string("backup.contents")) {
                LabeledContent(
                    FormulaL10n.string("backup.custom_recipes"),
                    value: FormulaL10n.format("common.recipes_count", customRecipeStore.recipes.count)
                )
                LabeledContent(
                    FormulaL10n.string("backup.favorites"),
                    value: FormulaL10n.format("common.recipes_count", favoriteStore.count)
                )
                LabeledContent(FormulaL10n.string("backup.coin_balance"), value: "\(coinStore.coins)")
                LabeledContent(
                    FormulaL10n.string("backup.unlocked"),
                    value: FormulaL10n.format("common.recipes_count", coinStore.unlockedCount)
                )
            }
        }
        .centeredNavigationTitle(FormulaL10n.string("backup.title"))
        .fileExporter(
            isPresented: $showExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "diy_formula_backup.json"
        ) { result in
            if case .failure(let error) = result {
                alertMessage = FormulaL10n.format("backup.export_failed", error.localizedDescription)
                showAlert = true
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .alert(FormulaL10n.string("backup.import_confirm"), isPresented: $showImportConfirm) {
            Button(FormulaL10n.string("common.cancel"), role: .cancel) {
                pendingImportURL = nil
                pendingImportSummary = nil
            }
            Button(FormulaL10n.string("backup.import_overwrite"), role: .destructive) {
                performImport()
            }
        } message: {
            Text(pendingImportSummary ?? "")
        }
        .alert(FormulaL10n.string("alert.title"), isPresented: $showAlert) {
            Button(FormulaL10n.string("alert.ok"), role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func exportBackup() {
        let backup = BackupService.makeBackup(
            customRecipes: customRecipeStore.recipes,
            favoriteIDs: favoriteStore.exportIDs(),
            coins: coinStore.exportCoins(),
            unlockedRecipeIDs: coinStore.exportUnlockedIDs()
        )

        do {
            let url = try BackupService.exportURL(from: backup)
            backupDocument = BackupFileDocument(fileURL: url)
            showExporter = true
        } catch {
            alertMessage = FormulaL10n.format("backup.export_failed", error.localizedDescription)
            showAlert = true
        }
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            switch BackupService.parseBackup(from: url) {
            case .success(let custom, let favorite, let coins, let unlocked):
                pendingImportURL = url
                pendingImportSummary = FormulaL10n.format(
                    "backup.import_summary",
                    custom, favorite, coins, unlocked
                )
                showImportConfirm = true
            case .invalidFormat:
                alertMessage = FormulaL10n.string("backup.invalid_format")
                showAlert = true
            case .unsupportedVersion:
                alertMessage = FormulaL10n.string("backup.unsupported_version")
                showAlert = true
            case .readFailed(let message):
                alertMessage = FormulaL10n.format("backup.read_failed", message)
                showAlert = true
            }
        case .failure(let error):
            alertMessage = FormulaL10n.format("backup.select_failed", error.localizedDescription)
            showAlert = true
        }
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil
        pendingImportSummary = nil

        do {
            let backup = try BackupService.loadBackup(from: url)
            customRecipeStore.importRecipes(backup.customRecipes)
            favoriteStore.importIDs(backup.favoriteIDs)
            coinStore.importData(coins: backup.coins, unlockedIDs: backup.unlockedRecipeIDs)
            alertMessage = FormulaL10n.format("backup.import_success_detail", backup.customRecipes.count)
            showAlert = true
        } catch {
            alertMessage = FormulaL10n.format("backup.import_failed", error.localizedDescription)
            showAlert = true
        }
    }
}

private struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try Data(contentsOf: fileURL)
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    NavigationStack {
        BackupSettingsView()
            .environment(CoinStore())
            .environment(FavoriteStore())
            .environment(CustomRecipeStore())
    }
}
