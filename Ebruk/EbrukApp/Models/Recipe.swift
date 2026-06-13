import SwiftUI

enum RecipeCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case cleaner = "清洁剂"
    case lubricant = "润滑油"
    case paint = "颜料"
    case glue = "胶水"
    case fragrance = "香料"
    case detergent = "洗涤剂"
    case cosmetics = "化妆品"
    case fertilizer = "肥料"
    case candle = "蜡烛"
    case soap = "手工皂"
    case repellent = "驱虫剂"
    case preservative = "防腐剂"
    case other = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cleaner: "sparkles"
        case .lubricant: "gearshape.2"
        case .paint: "paintpalette"
        case .glue: "drop.fill"
        case .fragrance: "leaf"
        case .detergent: "bubbles.and.sparkles"
        case .cosmetics: "face.smiling"
        case .fertilizer: "tree"
        case .candle: "flame"
        case .soap: "hands.sparkles"
        case .repellent: "ant.circle"
        case .preservative: "shield.lefthalf.filled"
        case .other: "ellipsis.circle"
        }
    }

    var localizedName: String {
        switch self {
        case .cleaner: FormulaL10n.string("category.cleaner")
        case .lubricant: FormulaL10n.string("category.lubricant")
        case .paint: FormulaL10n.string("category.paint")
        case .glue: FormulaL10n.string("category.glue")
        case .fragrance: FormulaL10n.string("category.fragrance")
        case .detergent: FormulaL10n.string("category.detergent")
        case .cosmetics: FormulaL10n.string("category.cosmetics")
        case .fertilizer: FormulaL10n.string("category.fertilizer")
        case .candle: FormulaL10n.string("category.candle")
        case .soap: FormulaL10n.string("category.soap")
        case .repellent: FormulaL10n.string("category.repellent")
        case .preservative: FormulaL10n.string("category.preservative")
        case .other: FormulaL10n.string("category.other")
        }
    }

    var color: Color {
        switch self {
        case .cleaner: .blue
        case .lubricant: .orange
        case .paint: .purple
        case .glue: .brown
        case .fragrance: .pink
        case .detergent: .teal
        case .cosmetics: .red
        case .fertilizer: .green
        case .candle: .yellow
        case .soap: .cyan
        case .repellent: .mint
        case .preservative: .gray
        case .other: .indigo
        }
    }
}

struct Recipe: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let category: RecipeCategory
    let materials: [String]
    let ratio: String
    let steps: String
    let safetyNote: String?
    let isCustom: Bool

    init(
        id: Int,
        name: String,
        category: RecipeCategory,
        materials: [String],
        ratio: String,
        steps: String,
        safetyNote: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.materials = materials
        self.ratio = ratio
        self.steps = steps
        self.safetyNote = safetyNote
        self.isCustom = isCustom
    }
}
