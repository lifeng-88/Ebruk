import SwiftUI

struct CoinBalanceView: View {
    @Bindable var coinStore: CoinStore
    @State private var showRecharge = false

    var body: some View {
        Button {
            showRecharge = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(.orange)
                Text("\(coinStore.coins)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .accessibilityLabel(FormulaL10n.string("coin.balance_a11y"))
        .sheet(isPresented: $showRecharge) {
            CoinRechargeView(coinStore: coinStore)
        }
    }
}
