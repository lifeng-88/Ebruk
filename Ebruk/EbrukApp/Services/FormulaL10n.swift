import Foundation
import SwiftUI

/// A 面 String Catalog（`Formula.xcstrings`）本地化
enum FormulaL10n {
    private static let table = "Formula"

    static var prefersEnglishUI: Bool {
        switch FormulaLanguagePreference.current {
        case .english:
            return true
        case .simplifiedChinese:
            return false
        case .system:
            let lang = Locale.preferredLanguages.first ?? ""
            return !lang.hasPrefix("zh")
        }
    }

    static func string(_ key: String) -> String {
        let value = String.LocalizationValue(key)
        let locale = localeForCurrentPreference()
        if #available(iOS 16.0, *) {
            let resource = LocalizedStringResource(
                value,
                table: table,
                locale: locale
            )
            return String(localized: resource)
        }
        return bundleForCurrentPreference().localizedString(forKey: key, value: nil, table: table)
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(
            format: string(key),
            locale: localeForCurrentPreference(),
            arguments: args
        )
    }

    static func localeForCurrentPreference() -> Locale {
        switch FormulaLanguagePreference.current {
        case .system:
            return Locale.autoupdatingCurrent
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        case .english:
            return Locale(identifier: "en")
        }
    }

    private static func bundleForCurrentPreference() -> Bundle {
        let langCode: String
        switch FormulaLanguagePreference.current {
        case .english:
            langCode = "en"
        case .simplifiedChinese:
            langCode = "zh-Hans"
        case .system:
            let preferred = Locale.preferredLanguages.first ?? ""
            langCode = preferred.hasPrefix("zh") ? "zh-Hans" : "en"
        }
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
}

struct FormulaLanguageRefreshModifier: ViewModifier {
    @Environment(AppSettingsStore.self) private var appSettings

    func body(content: Content) -> some View {
        let _ = appSettings.languagePreference
        content
    }
}

extension View {
    func formulaRefreshOnLanguageChange() -> some View {
        modifier(FormulaLanguageRefreshModifier())
    }
}
