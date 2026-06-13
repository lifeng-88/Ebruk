import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(FavoriteStore.self) private var favoriteStore
    @Environment(CustomRecipeStore.self) private var customRecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var showDeleteAlert = false
    @State private var pdfShareURL: URL?
    @State private var showPDFShareSheet = false
    @State private var exportErrorMessage: String?
    @State private var showExportError = false

    private var displayRecipe: Recipe { recipe.localized }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                materialsSection
                ratioSection
                stepsSection

                if let safetyNote = displayRecipe.safetyNote {
                    safetySection(safetyNote)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .centeredNavigationTitle(displayRecipe.name)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: recipe.shareText) {
                        Label(FormulaL10n.string("detail.share_text"), systemImage: "text.quote")
                    }

                    Button {
                        exportPDF()
                    } label: {
                        Label(FormulaL10n.string("detail.export_pdf"), systemImage: "doc.richtext")
                    }

                    Button {
                        RecipePDFExporter.printRecipe(recipe)
                    } label: {
                        Label(FormulaL10n.string("detail.print"), systemImage: "printer")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(FormulaL10n.string("detail.export_share"))

                if !recipe.isCustom {
                    Button {
                        favoriteStore.toggle(recipe)
                    } label: {
                        Image(systemName: favoriteStore.isFavorite(recipe) ? "heart.fill" : "heart")
                            .foregroundStyle(favoriteStore.isFavorite(recipe) ? .pink : .secondary)
                    }
                    .accessibilityLabel(
                        favoriteStore.isFavorite(recipe)
                            ? FormulaL10n.string("detail.unfavorite")
                            : FormulaL10n.string("detail.favorite")
                    )
                }

                if recipe.isCustom {
                    Menu {
                        Button {
                            showEditor = true
                        } label: {
                            Label(FormulaL10n.string("detail.edit"), systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label(FormulaL10n.string("common.delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(recipe: recipe)
        }
        .sheet(isPresented: $showPDFShareSheet, onDismiss: {
            pdfShareURL = nil
        }) {
            if let pdfShareURL {
                ActivityShareSheet(items: [pdfShareURL])
                    .presentationDetents([.medium, .large])
            }
        }
        .alert(FormulaL10n.string("detail.export_failed"), isPresented: $showExportError) {
            Button(FormulaL10n.string("alert.ok"), role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
        .alert(FormulaL10n.string("detail.delete_recipe"), isPresented: $showDeleteAlert) {
            Button(FormulaL10n.string("common.delete"), role: .destructive) {
                favoriteStore.remove(recipe)
                customRecipeStore.delete(recipe)
                dismiss()
            }
            Button(FormulaL10n.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(FormulaL10n.string("detail.delete_confirm"))
        }
    }

    private func exportPDF() {
        do {
            pdfShareURL = try RecipePDFExporter.temporaryPDFURL(for: recipe)
            showPDFShareSheet = true
        } catch {
            exportErrorMessage = error.localizedDescription
            showExportError = true
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(recipe.category.color.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: recipe.category.icon)
                    .font(.title2)
                    .foregroundStyle(recipe.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.category.localizedName)
                    .font(.subheadline)
                    .foregroundStyle(recipe.category.color)
                HStack(spacing: 6) {
                    Text(
                        recipe.isCustom
                            ? FormulaL10n.string("detail.custom_recipe")
                            : FormulaL10n.format("detail.recipe_id", recipe.id)
                    )
                    if recipe.isCustom {
                        Text(FormulaL10n.string("common.custom"))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.15))
                            .foregroundStyle(.indigo)
                            .clipShape(Capsule())
                    } else if RecipeAccessPolicy.isFree(recipe) {
                        Text(FormulaL10n.string("common.free"))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var materialsSection: some View {
        DetailSection(title: FormulaL10n.string("detail.materials"), icon: "leaf") {
            FlowLayout(spacing: 8) {
                ForEach(displayRecipe.materials, id: \.self) { material in
                    Text(material)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(recipe.category.color.opacity(0.12))
                        .foregroundStyle(recipe.category.color)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var ratioSection: some View {
        DetailSection(title: FormulaL10n.string("detail.ratio"), icon: "scalemass") {
            Text(displayRecipe.ratio)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var stepsSection: some View {
        DetailSection(title: FormulaL10n.string("detail.steps"), icon: "list.number") {
            Text(displayRecipe.steps)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func safetySection(_ note: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(FormulaL10n.string("detail.safety"))
                    .font(.subheadline.weight(.semibold))
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
