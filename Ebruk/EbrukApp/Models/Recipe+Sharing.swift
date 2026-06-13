import Foundation

extension Recipe {
    var shareText: String {
        let display = localized
        var lines = [
            FormulaL10n.format("share.title", display.name),
            FormulaL10n.format("share.category", category.localizedName),
            "",
            FormulaL10n.string("share.materials_header")
        ]

        if display.materials.isEmpty {
            lines.append(FormulaL10n.string("share.none"))
        } else {
            lines.append(contentsOf: display.materials.map { "• \($0)" })
        }

        lines.append("")
        lines.append(FormulaL10n.string("share.ratio_header"))
        lines.append(display.ratio)
        lines.append("")
        lines.append(FormulaL10n.string("share.steps_header"))
        lines.append(display.steps)

        if let safetyNote = display.safetyNote, !safetyNote.isEmpty {
            lines.append("")
            lines.append(FormulaL10n.string("share.safety_header"))
            lines.append(safetyNote)
        }

        lines.append("")
        lines.append(FormulaL10n.string("share.footer"))
        return lines.joined(separator: "\n")
    }
}
