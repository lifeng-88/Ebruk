import Foundation
import SwiftUI

@Observable
@MainActor
final class AppSettingsStore {
    var languagePreference: FormulaLanguagePreference {
        didSet { persist() }
    }

    var appearanceMode: AppearanceMode {
        didSet { persist() }
    }

    var effectiveLocale: Locale {
        switch languagePreference {
        case .system:
            return Locale.autoupdatingCurrent
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        case .english:
            return Locale(identifier: "en")
        }
    }

    var dailyReminderEnabled: Bool {
        didSet { persist() }
    }

    var dailyReminderHour: Int {
        didSet { persist() }
    }

    var dailyReminderMinute: Int {
        didSet { persist() }
    }

    var dailyReminderDate: Date {
        get {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            components.hour = dailyReminderHour
            components.minute = dailyReminderMinute
            return Calendar.current.date(from: components) ?? .now
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailyReminderHour = components.hour ?? 9
            dailyReminderMinute = components.minute ?? 0
        }
    }

    private let languageKey = FormulaLanguagePreference.userDefaultsKey
    private let appearanceKey = "diy_formula_appearance"
    private let reminderEnabledKey = "diy_formula_daily_reminder_enabled"
    private let reminderHourKey = "diy_formula_daily_reminder_hour"
    private let reminderMinuteKey = "diy_formula_daily_reminder_minute"

    init() {
        let defaults = UserDefaults.standard
        languagePreference = FormulaLanguagePreference.from(
            storage: defaults.string(forKey: languageKey) ?? "system"
        )
        appearanceMode = AppearanceMode(
            rawValue: defaults.string(forKey: appearanceKey) ?? ""
        ) ?? .system
        dailyReminderEnabled = defaults.bool(forKey: reminderEnabledKey)

        if defaults.object(forKey: reminderHourKey) == nil {
            dailyReminderHour = 9
            dailyReminderMinute = 0
        } else {
            dailyReminderHour = defaults.integer(forKey: reminderHourKey)
            dailyReminderMinute = defaults.integer(forKey: reminderMinuteKey)
        }
    }

    func restoreDailyReminderIfNeeded() async {
        guard dailyReminderEnabled else { return }
        let status = await NotificationService.authorizationStatus()
        guard status == .authorized || status == .provisional else { return }
        await NotificationService.scheduleDailyReminder(
            hour: dailyReminderHour,
            minute: dailyReminderMinute
        )
    }

    func setDailyReminderEnabled(_ enabled: Bool) async -> DailyReminderResult {
        if enabled {
            let status = await NotificationService.authorizationStatus()
            if status == .denied {
                return .permissionDenied
            }

            if status == .notDetermined {
                let granted = await NotificationService.requestAuthorization()
                guard granted else {
                    return .permissionDenied
                }
            }

            dailyReminderEnabled = true
            await NotificationService.scheduleDailyReminder(
                hour: dailyReminderHour,
                minute: dailyReminderMinute
            )
            return .enabled
        } else {
            dailyReminderEnabled = false
            NotificationService.cancelDailyReminder()
            return .disabled
        }
    }

    func updateDailyReminderTime() async {
        guard dailyReminderEnabled else { return }
        await NotificationService.scheduleDailyReminder(
            hour: dailyReminderHour,
            minute: dailyReminderMinute
        )
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(languagePreference.storageValue, forKey: languageKey)
        defaults.set(appearanceMode.rawValue, forKey: appearanceKey)
        defaults.set(dailyReminderEnabled, forKey: reminderEnabledKey)
        defaults.set(dailyReminderHour, forKey: reminderHourKey)
        defaults.set(dailyReminderMinute, forKey: reminderMinuteKey)
    }
}

enum DailyReminderResult {
    case enabled
    case disabled
    case permissionDenied
}
