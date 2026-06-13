import SwiftUI

struct UnlockRecipeSheet: View {
    let recipe: Recipe
    @Bindable var coinStore: CoinStore
    var onUnlocked: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var alertMessage: String?
    @State private var showRecharge = false

    private var cost: Int { RecipeAccessPolicy.unlockCost(for: recipe) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(recipe.category.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(recipe.category.color)
                }

                VStack(spacing: 8) {
                    Text(recipe.localized.name)
                        .font(.title2.bold())

                    Text(recipe.category.localizedName)
                        .font(.subheadline)
                        .foregroundStyle(recipe.category.color)
                }

                VStack(spacing: 12) {
                    HStack {
                        Label(FormulaL10n.string("unlock.cost"), systemImage: "dollarsign.circle.fill")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(FormulaL10n.format("common.coins_count", cost))
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                            Text(RecipeAccessPolicy.difficultyLabel(for: recipe))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Label(FormulaL10n.string("unlock.balance"), systemImage: "bitcoinsign.circle")
                        Spacer()
                        Text(FormulaL10n.format("common.coins_count", coinStore.coins))
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text(FormulaL10n.string("unlock.hint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    unlock()
                } label: {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text(
                            coinStore.coins >= cost
                                ? FormulaL10n.format("unlock.spend", cost)
                                : FormulaL10n.string("unlock.insufficient")
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(coinStore.coins < cost)

                if coinStore.coins < cost {
                    VStack(spacing: 10) {
                        Button {
                            showRecharge = true
                        } label: {
                            Label(FormulaL10n.string("settings.recharge"), systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(FormulaL10n.format("unlock.claim_daily", RecipeAccessPolicy.dailyBonusAmount)) {
                            if coinStore.claimDailyBonus() {
                                alertMessage = FormulaL10n.format("unlock.claimed", RecipeAccessPolicy.dailyBonusAmount)
                            } else {
                                alertMessage = FormulaL10n.string("settings.daily_claim_done")
                            }
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()
            }
            .padding()
            .centeredNavigationTitle(FormulaL10n.string("unlock.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(FormulaL10n.string("common.close")) { dismiss() }
                }
            }
            .sheet(isPresented: $showRecharge) {
                CoinRechargeView(coinStore: coinStore)
            }
            .alert(FormulaL10n.string("alert.title"), isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button(FormulaL10n.string("alert.ok"), role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
        .presentationDetents([.medium])
    }

    private func unlock() {
        switch coinStore.unlock(recipe: recipe) {
        case .success, .alreadyUnlocked:
            dismiss()
            onUnlocked()
        case .insufficientCoins:
            alertMessage = FormulaL10n.string("unlock.insufficient_hint")
        }
    }
}
