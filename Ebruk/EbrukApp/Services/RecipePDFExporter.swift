import UIKit

enum RecipePDFExporter {
    private static let pageSize = CGSize(width: 595.2, height: 841.8)
    private static let margin: CGFloat = 48
    private static let contentWidth: CGFloat = 595.2 - 96

    static func generatePDF(for recipe: Recipe) -> Data {
        let display = recipe.localized
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        return renderer.pdfData { context in
            var y = margin
            beginPage(context: context, y: &y)

            y = drawTitle(display.name, y: y, context: context)
            y = drawMeta(recipe: recipe, y: y, context: context)
            y = drawSection(
                title: FormulaL10n.string("detail.materials"),
                body: materialsText(display),
                y: y,
                context: context
            )
            y = drawSection(
                title: FormulaL10n.string("detail.ratio"),
                body: display.ratio,
                y: y,
                context: context
            )
            y = drawSection(
                title: FormulaL10n.string("detail.steps"),
                body: display.steps,
                y: y,
                context: context
            )

            if let safetyNote = display.safetyNote, !safetyNote.isEmpty {
                y = drawSafetyNote(safetyNote, y: y, context: context)
            }

            drawFooter(y: y, context: context)
        }
    }

    static func temporaryPDFURL(for recipe: Recipe) throws -> URL {
        let display = recipe.localized
        let data = generatePDF(for: recipe)
        let sanitized = display.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let filename = "\(FormulaL10n.string("pdf.filename_prefix"))\(sanitized).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func printRecipe(_ recipe: Recipe) {
        let display = recipe.localized
        let data = generatePDF(for: recipe)
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.jobName = display.name
        info.outputType = .general
        controller.printInfo = info
        controller.printingItem = data

        guard let presenter = topViewController() else { return }
        controller.present(
            from: presenter.view.bounds,
            in: presenter.view,
            animated: true,
            completionHandler: nil
        )
    }

    private static func beginPage(context: UIGraphicsPDFRendererContext, y: inout CGFloat) {
        context.beginPage()
        y = margin
    }

    private static func ensureSpace(
        _ required: CGFloat,
        y: inout CGFloat,
        context: UIGraphicsPDFRendererContext
    ) {
        if y + required > pageSize.height - margin {
            beginPage(context: context, y: &y)
        }
    }

    private static func drawTitle(
        _ title: String,
        y: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var cursor = y
        let font = UIFont.systemFont(ofSize: 26, weight: .bold)
        cursor = drawText(title, font: font, color: .black, y: cursor, context: context, spacing: 8)

        let lineY = cursor
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: lineY))
        path.addLine(to: CGPoint(x: pageSize.width - margin, y: lineY))
        UIColor(red: 0.18, green: 0.34, blue: 0.42, alpha: 1).setStroke()
        path.lineWidth = 2
        path.stroke()

        return lineY + 16
    }

    private static func drawMeta(recipe: Recipe, y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var cursor = y
        var tags = [FormulaL10n.format("pdf.category", recipe.category.localizedName)]
        if recipe.isCustom {
            tags.append(FormulaL10n.string("detail.custom_recipe"))
        } else if RecipeAccessPolicy.isFree(recipe) {
            tags.append(FormulaL10n.string("common.free"))
        } else {
            tags.append(FormulaL10n.format("detail.recipe_id", recipe.id))
        }

        let formatter = DateFormatter()
        formatter.locale = FormulaL10n.localeForCurrentPreference()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        tags.append(FormulaL10n.format("pdf.exported_at", formatter.string(from: .now)))

        let meta = tags.joined(separator: "  ·  ")
        cursor = drawText(
            meta,
            font: .systemFont(ofSize: 11),
            color: .darkGray,
            y: cursor,
            context: context,
            spacing: 20
        )
        return cursor
    }

    private static func drawSection(
        title: String,
        body: String,
        y: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var cursor = y
        ensureSpace(40, y: &cursor, context: context)

        cursor = drawText(
            title,
            font: .systemFont(ofSize: 16, weight: .semibold),
            color: UIColor(red: 0.18, green: 0.34, blue: 0.42, alpha: 1),
            y: cursor,
            context: context,
            spacing: 8
        )

        cursor = drawText(
            body,
            font: .systemFont(ofSize: 13),
            color: .black,
            y: cursor,
            context: context,
            spacing: 24
        )
        return cursor
    }

    private static func drawSafetyNote(
        _ note: String,
        y: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var cursor = y
        ensureSpace(80, y: &cursor, context: context)

        let boxX = margin
        let boxWidth = contentWidth
        let title = FormulaL10n.string("detail.safety")
        let body = note
        let titleHeight = heightForText(title, font: .systemFont(ofSize: 14, weight: .semibold), width: boxWidth - 24)
        let bodyHeight = heightForText(body, font: .systemFont(ofSize: 12), width: boxWidth - 24)
        let boxHeight = titleHeight + bodyHeight + 28

        ensureSpace(boxHeight, y: &cursor, context: context)

        let boxRect = CGRect(x: boxX, y: cursor, width: boxWidth, height: boxHeight)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        UIColor.orange.withAlphaComponent(0.12).setFill()
        boxPath.fill()

        var innerY = cursor + 12
        innerY = drawText(
            title,
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: .orange,
            y: innerY,
            x: boxX + 12,
            width: boxWidth - 24,
            context: context,
            spacing: 6
        )
        innerY = drawText(
            body,
            font: .systemFont(ofSize: 12),
            color: .darkGray,
            y: innerY,
            x: boxX + 12,
            width: boxWidth - 24,
            context: context,
            spacing: 0
        )
        return boxRect.maxY + 20
    }

    private static func drawFooter(y: CGFloat, context: UIGraphicsPDFRendererContext) {
        var cursor = y
        ensureSpace(30, y: &cursor, context: context)
        _ = drawText(
            FormulaL10n.string("pdf.footer"),
            font: .systemFont(ofSize: 10),
            color: .gray,
            y: cursor,
            context: context,
            spacing: 0
        )
    }

    private static func materialsText(_ recipe: Recipe) -> String {
        if recipe.materials.isEmpty {
            return FormulaL10n.string("share.none")
        }
        return recipe.materials.map { "• \($0)" }.joined(separator: "\n")
    }

    @discardableResult
    private static func drawText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        y: CGFloat,
        x: CGFloat = margin,
        width: CGFloat = contentWidth,
        context: UIGraphicsPDFRendererContext,
        spacing: CGFloat
    ) -> CGFloat {
        var cursor = y
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 4

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]

        let textHeight = heightForText(text, font: font, width: width, paragraph: paragraph)
        ensureSpace(textHeight + spacing, y: &cursor, context: context)

        let rect = CGRect(x: x, y: cursor, width: width, height: textHeight)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        return cursor + textHeight + spacing
    }

    private static func heightForText(
        _ text: String,
        font: UIFont,
        width: CGFloat,
        paragraph: NSParagraphStyle? = nil
    ) -> CGFloat {
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        if let paragraph {
            attributes[.paragraphStyle] = paragraph
        }
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(rect.height)
    }

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
