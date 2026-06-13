import SwiftUI

struct PurchaseHistoryView: View {
    @Environment(StoreKitService.self) private var storeKitService
    @Environment(AppSettingsStore.self) private var appSettings

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = appSettings.effectiveLocale
        return formatter
    }

    var body: some View {
        Group {
            if storeKitService.purchaseHistory.isEmpty {
                ContentUnavailableView {
                    Label(FormulaL10n.string("purchase.empty"), systemImage: "creditcard")
                } description: {
                    Text(FormulaL10n.string("purchase.empty_hint"))
                }
            } else {
                List(storeKitService.purchaseHistory) { record in
                    HStack(spacing: 12) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.packageName)
                                .font(.headline)
                            Text(dateFormatter.string(from: record.purchasedAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if record.environment == "Xcode" || record.environment == "Sandbox" {
                            Text(FormulaL10n.string("common.test"))
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .centeredNavigationTitle(FormulaL10n.string("purchase.title"))
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        PurchaseHistoryView()
            .environment(StoreKitService())
            .environment(AppSettingsStore())
    }
}
