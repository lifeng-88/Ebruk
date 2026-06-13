import Foundation

extension Recipe {
    /// 按当前语言偏好返回展示用配方（内置配方支持英文；自创配方保持原文）
    var localized: Recipe {
        RecipeLocalization.localized(self)
    }
}
