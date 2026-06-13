import SwiftUI

struct CoinRechargeView: View {
    @Bindable var coinStore: CoinStore
    @Environment(StoreKitService.self) private var storeKitService
    @Environment(\.dismiss) private var dismiss

    @State private var purchasingPackageID: String?
    @State private var alertMessage: String?
    @State private var showAlert = false

    private let packageColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    balanceCard
                    packagesSection
                    bonusSection
                    disclaimer
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .centeredNavigationTitle(FormulaL10n.string("recharge.title"))
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        restorePurchases()
                    } label: {
                        if storeKitService.isRestoring {
                            ProgressView()
                        } else {
                            Text(FormulaL10n.string("recharge.restore"))
                        }
                    }
                    .disabled(storeKitService.isRestoring || purchasingPackageID != nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(FormulaL10n.string("common.done")) { dismiss() }
                }
            }
            .task {
                await storeKitService.loadProducts()
            }
            .alert(FormulaL10n.string("alert.title"), isPresented: $showAlert) {
                Button(FormulaL10n.string("alert.ok"), role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var balanceCard: some View {
        VStack(spacing: 10) {
            Text(FormulaL10n.string("recharge.balance"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text("\(coinStore.coins)")
                    .font(.system(size: 36, weight: .bold))
                Text(FormulaL10n.string("common.coins"))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                usageTip(
                    icon: "lock.open.fill",
                    text: FormulaL10n.format(
                        "recharge.usage_unlock",
                        RecipeAccessPolicy.minUnlockCost,
                        RecipeAccessPolicy.maxUnlockCost
                    )
                )
                usageTip(
                    icon: "gift.fill",
                    text: FormulaL10n.format("recharge.usage_checkin", RecipeAccessPolicy.dailyBonusAmount)
                )
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func usageTip(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .labelStyle(.titleAndIcon)
    }

    private var packagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(FormulaL10n.string("recharge.choose_package"))
                    .font(.headline)
                Spacer()
                if storeKitService.isLoadingProducts {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text(FormulaL10n.string("recharge.package_hint"))
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: packageColumns, spacing: 12) {
                ForEach(CoinPackage.all) { package in
                    packageCard(package)
                }
            }
        }
    }

    private func packageCard(_ package: CoinPackage) -> some View {
        let isPurchasing = purchasingPackageID == package.id

        return Button {
            purchase(package)
        } label: {
            VStack(spacing: 10) {
                HStack {
                    if let badge = package.localizedBadge {
                        Text(badge)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(badgeBackground(for: package))
                            .foregroundStyle(badgeForeground(for: package))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                    if package.isRecommended {
                        Text(FormulaL10n.string("recharge.recommended"))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(package.coins)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(FormulaL10n.string("common.coins"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    if package.bonusCoins > 0 {
                        Text(FormulaL10n.format("recharge.bonus", package.bonusCoins))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }

                Text(package.unlockRecipeDescription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if isPurchasing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    Text(storeKitService.displayPrice(for: package))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 168)
            .background(Color(.secondarySystemGroupedBackground))
            .overlay {
                if package.isRecommended {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.55), lineWidth: 1.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(purchasingPackageID != nil)
    }

    private func badgeBackground(for package: CoinPackage) -> Color {
        package.isRecommended ? Color.orange.opacity(0.18) : Color.secondary.opacity(0.12)
    }

    private func badgeForeground(for package: CoinPackage) -> Color {
        package.isRecommended ? .orange : .secondary
    }

    private var bonusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(FormulaL10n.string("recharge.free_section"))
                .font(.headline)

            Button {
                if coinStore.claimDailyBonus() {
                    alertMessage = FormulaL10n.format(
                        "settings.daily_claim_ok",
                        RecipeAccessPolicy.dailyBonusAmount
                    )
                } else {
                    alertMessage = FormulaL10n.string("settings.daily_claim_done")
                }
                showAlert = true
            } label: {
                HStack {
                    Label(FormulaL10n.string("recharge.daily_reward"), systemImage: "gift.fill")
                    Spacer()
                    Text("+\(RecipeAccessPolicy.dailyBonusAmount)")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var disclaimer: some View {
        Text(FormulaL10n.string("recharge.iap_note"))
            .font(.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func restorePurchases() {
        Task {
            let result = await storeKitService.restorePurchases()
            switch result {
            case .restored(let coins, let count):
                alertMessage = FormulaL10n.format("settings.restore_ok", count, coins)
                showAlert = true
            case .nothingToRestore:
                alertMessage = FormulaL10n.string("settings.restore_none")
                showAlert = true
            case .failed(let message):
                alertMessage = message
                showAlert = true
            }
        }
    }

    private func purchase(_ package: CoinPackage) {
        purchasingPackageID = package.id
        Task {
            let result = await storeKitService.purchase(package: package)
            purchasingPackageID = nil

            switch result {
            case .success(let coins):
                if package.bonusCoins > 0 {
                    alertMessage = FormulaL10n.format("recharge.buy_ok_bonus", coins, package.bonusCoins)
                } else {
                    alertMessage = FormulaL10n.format("recharge.buy_ok", coins)
                }
                showAlert = true
            case .cancelled:
                break
            case .pending:
                alertMessage = FormulaL10n.string("recharge.buy_pending")
                showAlert = true
            case .failed(let message):
                alertMessage = message
                showAlert = true
            }
        }
    }
}
