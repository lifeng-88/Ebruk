import SwiftUI

struct SettingsView: View {
    @Environment(CoinStore.self) private var coinStore
    @Environment(AppSettingsStore.self) private var appSettings
    @Environment(StoreKitService.self) private var storeKitService
    @Environment(UserStore.self) private var userStore

    @State private var showRecharge = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var reminderToggle = false

    private let avatarSecretTapRequired = 10
    private let avatarSecretTapWindowSeconds: TimeInterval = 5
    @State private var avatarSecretTapCount = 0
    @State private var avatarSecretTapResetTask: Task<Void, Never>?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                languageSection
                appearanceSection
                reminderSection
                coinSection
                purchaseSection
                legalSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(16)
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, 16, for: .scrollContent)
            .centeredNavigationTitle(FormulaL10n.string("settings.title"))
            .onAppear {
                reminderToggle = appSettings.dailyReminderEnabled
            }
            .sheet(isPresented: $showRecharge) {
                CoinRechargeView(coinStore: coinStore)
            }
            .alert(FormulaL10n.string("alert.title"), isPresented: $showAlert) {
                Button(FormulaL10n.string("alert.ok"), role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var accountSection: some View {
        Section {
            HStack(spacing: 14) {
                accountAvatar

                VStack(alignment: .leading, spacing: 4) {
                    Text(FormulaL10n.string("settings.user_id"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(userStore.userID)
                        .font(.subheadline.monospaced().weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                Button {
                    UIPasteboard.general.string = userStore.userID
                    alertMessage = FormulaL10n.string("settings.user_id_copied")
                    showAlert = true
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(FormulaL10n.string("settings.copy_user_id"))
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        } footer: {
            Text(FormulaL10n.string("settings.user_id_footer"))
        }
    }

    private var languageSection: some View {
        Section(FormulaL10n.string("language.title")) {
            Picker(FormulaL10n.string("language.title"), selection: Binding(
                get: { appSettings.languagePreference },
                set: { appSettings.languagePreference = $0 }
            )) {
                ForEach(FormulaLanguagePreference.allCases) { language in
                    Text(FormulaL10n.string(language.displayNameKey)).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var appearanceSection: some View {
        Section(FormulaL10n.string("settings.appearance")) {
            Picker(FormulaL10n.string("settings.theme"), selection: Binding(
                get: { appSettings.appearanceMode },
                set: { appSettings.appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var reminderSection: some View {
        Section(FormulaL10n.string("settings.reminder")) {
            Toggle(FormulaL10n.string("settings.daily_reminder"), isOn: $reminderToggle)
                .onChange(of: reminderToggle) { _, enabled in
                    Task {
                        let result = await appSettings.setDailyReminderEnabled(enabled)
                        switch result {
                        case .enabled, .disabled:
                            break
                        case .permissionDenied:
                            reminderToggle = false
                            alertMessage = FormulaL10n.string("settings.reminder_denied")
                            showAlert = true
                        }
                    }
                }

            if reminderToggle {
                DatePicker(
                    FormulaL10n.string("settings.reminder_time"),
                    selection: Binding(
                        get: { appSettings.dailyReminderDate },
                        set: { newValue in
                            appSettings.dailyReminderDate = newValue
                            Task {
                                await appSettings.updateDailyReminderTime()
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            Text(FormulaL10n.string("settings.reminder_footer"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var coinSection: some View {
        Section(FormulaL10n.string("settings.coins")) {
            LabeledContent(FormulaL10n.string("settings.balance")) {
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundStyle(.orange)
                    Text("\(coinStore.coins)")
                        .fontWeight(.semibold)
                }
            }

            Button {
                showRecharge = true
            } label: {
                Label(FormulaL10n.string("settings.recharge"), systemImage: "plus.circle.fill")
            }

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
                Label(
                    FormulaL10n.format("settings.daily_checkin", RecipeAccessPolicy.dailyBonusAmount),
                    systemImage: "gift.fill"
                )
            }

            NavigationLink {
                UnlockedRecipesView()
            } label: {
                LabeledContent(
                    FormulaL10n.string("settings.unlocked_recipes"),
                    value: FormulaL10n.format("common.recipes_count", coinStore.unlockedCount)
                )
            }
        }
    }

    private var purchaseSection: some View {
        Section(FormulaL10n.string("settings.purchase")) {
            Button {
                Task { await restorePurchases() }
            } label: {
                HStack {
                    Label(FormulaL10n.string("settings.restore"), systemImage: "arrow.clockwise.circle")
                    Spacer()
                    if storeKitService.isRestoring {
                        ProgressView()
                    }
                }
            }
            .disabled(storeKitService.isRestoring)

            NavigationLink {
                PurchaseHistoryView()
            } label: {
                Label(FormulaL10n.string("settings.purchase_history"), systemImage: "list.bullet.rectangle")
            }
        }
    }

    private var legalSection: some View {
        Section(FormulaL10n.string("settings.legal")) {
            NavigationLink {
                LegalDocumentView(document: .privacyPolicy)
            } label: {
                Label(FormulaL10n.string("settings.privacy"), systemImage: "hand.raised")
            }

            NavigationLink {
                LegalDocumentView(document: .termsOfService)
            } label: {
                Label(FormulaL10n.string("settings.terms"), systemImage: "doc.text")
            }
        }
    }

    private var aboutSection: some View {
        Section(FormulaL10n.string("settings.about")) {
            LabeledContent(FormulaL10n.string("settings.app_name_label"), value: FormulaL10n.string("app.name"))
            Button {
                AppSurfaceController.shared.registerSecretTap()
            } label: {
                LabeledContent(FormulaL10n.string("settings.version"), value: appVersion)
            }
            .buttonStyle(.plain)
        }
    }

    private var accountAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.indigo.opacity(0.15))
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.indigo)
        }
        .frame(width: 48, height: 48)
        .contentShape(Circle())
        .onTapGesture {
            registerAvatarSecretTap()
        }
        .accessibilityLabel(FormulaL10n.string("settings.user_avatar"))
        .accessibilityAddTraits(.isButton)
    }

    /// 连续点击用户头像 10 次（5 秒内无中断则重新计数）复制 `dev_id`。
    private func registerAvatarSecretTap() {
        avatarSecretTapResetTask?.cancel()
        avatarSecretTapCount += 1

        guard avatarSecretTapCount >= avatarSecretTapRequired else {
            avatarSecretTapResetTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(avatarSecretTapWindowSeconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                avatarSecretTapCount = 0
            }
            return
        }

        avatarSecretTapResetTask?.cancel()
        avatarSecretTapCount = 0

        Task {
            let devId = await DeviceManager.shared.getDeviceId()
            await MainActor.run {
                UIPasteboard.general.string = devId
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                alertMessage = FormulaL10n.string("settings.dev_id_copied")
                showAlert = true
            }
        }
    }

    private func restorePurchases() async {
        let result = await storeKitService.restorePurchases()
        switch result {
        case .restored(let coins, let count):
            alertMessage = FormulaL10n.format("settings.restore_ok", count, coins)
        case .nothingToRestore:
            alertMessage = FormulaL10n.string("settings.restore_none")
        case .failed(let message):
            alertMessage = message
        }
        showAlert = true
    }
}

#Preview {
    SettingsView()
        .environment(CoinStore())
        .environment(AppSettingsStore())
        .environment(StoreKitService())
        .environment(UserStore())
}
