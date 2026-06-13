import SwiftUI

struct MainTabView: View {
    @AppStorage("diy_formula_has_seen_onboarding") private var hasSeenOnboarding = false
    @State private var coinStore = CoinStore()
    @State private var favoriteStore = FavoriteStore()
    @State private var customRecipeStore = CustomRecipeStore()
    @State private var recipeListViewModel = RecipeListViewModel()
    @State private var appSettings = AppSettingsStore()
    @State private var storeKitService = StoreKitService()
    @State private var userStore = UserStore()

    var body: some View {
        Group {
            if hasSeenOnboarding {
                mainTabs
            } else {
                OnboardingView()
            }
        }
        .environment(coinStore)
        .environment(favoriteStore)
        .environment(customRecipeStore)
        .environment(recipeListViewModel)
        .environment(appSettings)
        .environment(storeKitService)
        .environment(userStore)
        .environment(\.locale, appSettings.effectiveLocale)
        .formulaRefreshOnLanguageChange()
        .preferredColorScheme(appSettings.appearanceMode.colorScheme)
        .task {
            await appSettings.restoreDailyReminderIfNeeded()
            await storeKitService.processUnfinishedTransactionsOnLaunch()
            await storeKitService.loadProducts()
        }
    }

    private var mainTabs: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(FormulaL10n.string("tab.recipes"), systemImage: "list.bullet")
                }

            FavoriteRecipesView()
                .tabItem {
                    Label(FormulaL10n.string("tab.favorites"), systemImage: "heart.fill")
                }

            CustomRecipesView()
                .tabItem {
                    Label(FormulaL10n.string("tab.mine"), systemImage: "square.and.pencil")
                }

            SettingsView()
                .tabItem {
                    Label(FormulaL10n.string("tab.settings"), systemImage: "gearshape")
                }
        }
        .onAppear {
            storeKitService.attach(coinStore: coinStore)
        }
    }
}

#Preview {
    MainTabView()
}
