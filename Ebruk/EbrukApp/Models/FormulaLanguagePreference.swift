import Foundation

/// A 面应用内语言（跟随系统 / 简体中文 / English）
enum FormulaLanguagePreference: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    static let userDefaultsKey = "diy_formula_language"

    var storageValue: String {
        switch self {
        case .system: return "system"
        default: return rawValue
        }
    }

    static func from(storage: String) -> FormulaLanguagePreference {
        switch storage {
        case "system": return .system
        case simplifiedChinese.rawValue: return .simplifiedChinese
        case english.rawValue: return .english
        default: return .system
        }
    }

    static var current: FormulaLanguagePreference {
        let raw = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "system"
        return from(storage: raw)
    }

    var displayNameKey: String {
        switch self {
        case .system: "language.system"
        case .simplifiedChinese: "language.simplified_chinese"
        case .english: "language.english"
        }
    }
}
