import SwiftUI

struct OnboardingView: View {
    @AppStorage("diy_formula_has_seen_onboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "flask.fill",
                color: .indigo,
                title: FormulaL10n.string("onboarding.welcome.title"),
                subtitle: FormulaL10n.string("onboarding.welcome.subtitle")
            ),
            OnboardingPage(
                icon: "bitcoinsign.circle.fill",
                color: .orange,
                title: FormulaL10n.string("onboarding.coins.title"),
                subtitle: FormulaL10n.format(
                    "onboarding.coins.subtitle",
                    RecipeAccessPolicy.minUnlockCost,
                    RecipeAccessPolicy.maxUnlockCost,
                    RecipeAccessPolicy.dailyBonusAmount
                )
            ),
            OnboardingPage(
                icon: "square.and.pencil",
                color: .purple,
                title: FormulaL10n.string("onboarding.custom.title"),
                subtitle: FormulaL10n.string("onboarding.custom.subtitle")
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            bottomBar
        }
        .background(Color(.systemGroupedBackground))
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1
                     ? FormulaL10n.string("onboarding.next")
                     : FormulaL10n.string("onboarding.start"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)

            if currentPage < pages.count - 1 {
                Button(FormulaL10n.string("onboarding.skip")) {
                    hasSeenOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

private struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingView()
}
