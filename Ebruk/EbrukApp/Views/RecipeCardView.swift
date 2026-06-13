import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    let isLocked: Bool
    let isFree: Bool
    var isFavorite: Bool = false
    var isCustom: Bool = false

    private var displayRecipe: Recipe { recipe.localized }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(recipe.category.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: isLocked ? "lock.fill" : recipe.category.icon)
                    .font(.title3)
                    .foregroundStyle(recipe.category.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(displayRecipe.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isCustom {
                        badge(FormulaL10n.string("common.custom"), color: .indigo)
                    }
                    if isFree {
                        badge(FormulaL10n.string("common.free"), color: .green)
                    } else if isLocked {
                        badge(
                            FormulaL10n.format(
                                "card.coins_difficulty",
                                RecipeAccessPolicy.unlockCost(for: recipe),
                                RecipeAccessPolicy.difficultyLabel(for: recipe)
                            ),
                            color: .orange
                        )
                    }
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.pink)
                    }
                }

                Text(recipe.category.localizedName)
                    .font(.caption)
                    .foregroundStyle(recipe.category.color)

                Text(isLocked ? FormulaL10n.string("card.unlock_to_view") : displayRecipe.materials.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: isLocked ? "lock" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isLocked ? 0.85 : 1)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
