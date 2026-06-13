import SwiftUI

private struct IngredientItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var quantity: String
    var unit: AmountUnit

    init(
        id: UUID = UUID(),
        name: String = "",
        quantity: String = "",
        unit: AmountUnit = AmountUnit.lastSelected
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }

    var displayAmount: String {
        let trimmedQuantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)

        if unit == .asNeeded {
            return unit.localizedName
        }
        if trimmedQuantity.isEmpty {
            return ""
        }
        return "\(trimmedQuantity) \(unit.localizedName)"
    }
}

struct RecipeEditorView: View {
    let recipe: Recipe?

    @Environment(CustomRecipeStore.self) private var customRecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: RecipeCategory = .cleaner
    @State private var ingredients: [IngredientItem] = [IngredientItem()]
    @State private var steps = ""
    @State private var safetyNote = ""
    @State private var showValidationAlert = false

    private var isEditing: Bool { recipe != nil }

    private var validIngredients: [IngredientItem] {
        ingredients.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var composedRatio: String {
        validIngredients
            .map { item in
                let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let amount = item.displayAmount
                return amount.isEmpty ? trimmedName : "\(trimmedName) \(amount)"
            }
            .joined(separator: FormulaL10n.prefersEnglishUI ? ", " : "，")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(FormulaL10n.string("editor.basic")) {
                    TextField(FormulaL10n.string("editor.name"), text: $name)
                    Picker(FormulaL10n.string("editor.category"), selection: $category) {
                        ForEach(RecipeCategory.allCases) { item in
                            Text(item.localizedName).tag(item)
                        }
                    }
                }

                ingredientsSection

                Section(FormulaL10n.string("editor.steps")) {
                    TextEditor(text: $steps)
                        .frame(minHeight: 120)
                }

                Section(FormulaL10n.string("editor.safety")) {
                    TextField(FormulaL10n.string("editor.safety_placeholder"), text: $safetyNote, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .centeredNavigationTitle(
                isEditing ? FormulaL10n.string("editor.edit_title") : FormulaL10n.string("editor.new_title")
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(FormulaL10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(FormulaL10n.string("editor.save")) { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadRecipe)
            .alert(FormulaL10n.string("editor.validation_title"), isPresented: $showValidationAlert) {
                Button(FormulaL10n.string("alert.ok"), role: .cancel) {}
            } message: {
                Text(FormulaL10n.string("editor.validation_message"))
            }
        }
    }

    private var ingredientsSection: some View {
        Section {
            ForEach($ingredients) { $item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(category.color)
                        TextField(FormulaL10n.string("editor.ingredient_name"), text: $item.name)
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "scalemass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 12)

                        if item.unit == .asNeeded {
                            Text(FormulaL10n.string("unit.as_needed"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            TextField(FormulaL10n.string("editor.quantity"), text: $item.quantity)
                                .keyboardType(.decimalPad)
                                .font(.subheadline)
                        }

                        Picker(FormulaL10n.string("editor.unit"), selection: $item.unit) {
                            ForEach(AmountUnit.allCases) { unit in
                                Text(unit.localizedName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: item.unit) { _, newUnit in
                            AmountUnit.lastSelected = newUnit
                            if newUnit == .asNeeded {
                                item.quantity = ""
                            }
                        }
                    }
                    .padding(.leading, 14)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteIngredients)

            Button {
                ingredients.append(IngredientItem())
            } label: {
                Label(FormulaL10n.string("editor.add_ingredient_row"), systemImage: "plus.circle.fill")
            }
        } header: {
            HStack {
                Text(FormulaL10n.string("editor.ingredients_header"))
                Spacer()
                Text(FormulaL10n.format("editor.ingredients_count", validIngredients.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if !composedRatio.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(FormulaL10n.string("editor.ratio_preview"))
                        .font(.caption.weight(.semibold))
                    Text(composedRatio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(FormulaL10n.string("editor.ratio_footer"))
            }
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        if ingredients.isEmpty {
            ingredients.append(IngredientItem())
        }
    }

    private func loadRecipe() {
        guard let recipe else { return }

        name = recipe.name
        category = recipe.category
        steps = recipe.steps
        safetyNote = recipe.safetyNote ?? ""
        ingredients = parseIngredients(from: recipe)

        if ingredients.isEmpty {
            ingredients = [IngredientItem()]
        }
    }

    private func parseIngredients(from recipe: Recipe) -> [IngredientItem] {
        let ratioParts = recipe.ratio
            .split(whereSeparator: { $0 == "，" || $0 == "," })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !ratioParts.isEmpty {
            return ratioParts.map { part in
                if let material = recipe.materials.first(where: { part.hasPrefix($0) }) {
                    let amountText = part.dropFirst(material.count)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let parsed = AmountUnit.parse(from: amountText)
                    return IngredientItem(
                        name: material,
                        quantity: parsed.quantity,
                        unit: parsed.unit
                    )
                }
                return IngredientItem(name: part, quantity: "", unit: .gram)
            }
        }

        return recipe.materials.map { IngredientItem(name: $0, quantity: "", unit: .gram) }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSteps = steps.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = safetyNote.trimmingCharacters(in: .whitespacesAndNewlines)

        let materials = validIngredients.map {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let ratio = composedRatio

        guard !trimmedName.isEmpty,
              !materials.isEmpty,
              !ratio.isEmpty,
              !trimmedSteps.isEmpty else {
            showValidationAlert = true
            return
        }

        if let recipe {
            let updated = Recipe(
                id: recipe.id,
                name: trimmedName,
                category: category,
                materials: materials,
                ratio: ratio,
                steps: trimmedSteps,
                safetyNote: note.isEmpty ? nil : note,
                isCustom: true
            )
            customRecipeStore.update(updated)
        } else {
            customRecipeStore.add(
                name: trimmedName,
                category: category,
                materials: materials,
                ratio: ratio,
                steps: trimmedSteps,
                safetyNote: note.isEmpty ? nil : note
            )
        }

        dismiss()
    }
}
