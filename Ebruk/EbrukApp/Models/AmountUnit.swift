import Foundation

enum AmountUnit: String, CaseIterable, Identifiable, Codable {
    case milliliter = "毫升"
    case liter = "升"
    case gram = "克"
    case kilogram = "千克"
    case piece = "个"
    case spoon = "勺"
    case drop = "滴"
    case portion = "份"
    case asNeeded = "适量"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .milliliter: FormulaL10n.string("unit.ml")
        case .liter: FormulaL10n.string("unit.l")
        case .gram: FormulaL10n.string("unit.g")
        case .kilogram: FormulaL10n.string("unit.kg")
        case .piece: FormulaL10n.string("unit.piece")
        case .spoon: FormulaL10n.string("unit.spoon")
        case .drop: FormulaL10n.string("unit.drop")
        case .portion: FormulaL10n.string("unit.portion")
        case .asNeeded: FormulaL10n.string("unit.as_needed")
        }
    }

    private static let lastSelectedKey = "diy_formula_last_amount_unit"

    static var lastSelected: AmountUnit {
        get {
            guard let raw = UserDefaults.standard.string(forKey: lastSelectedKey),
                  let unit = AmountUnit(rawValue: raw) else {
                return .gram
            }
            return unit
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: lastSelectedKey)
        }
    }

    static func parse(from text: String) -> (quantity: String, unit: AmountUnit) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("", .gram)
        }

        if trimmed == AmountUnit.asNeeded.rawValue {
            return ("", .asNeeded)
        }

        let sortedUnits = AmountUnit.allCases
            .filter { $0 != .asNeeded }
            .sorted { $0.rawValue.count > $1.rawValue.count }

        for unit in sortedUnits {
            if trimmed.hasSuffix(unit.rawValue) {
                let quantity = trimmed
                    .dropLast(unit.rawValue.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (quantity, unit)
            }
        }

        return (trimmed, .gram)
    }
}
