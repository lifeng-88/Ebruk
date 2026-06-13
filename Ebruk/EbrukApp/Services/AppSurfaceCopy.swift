import Foundation

/// A/B 面切换按钮文案（Debug 可见；Release 走隐蔽手势）
enum AppSurfaceCopy {
    /// A 面 → 进入 B 面
    static var enterBLabel: String { FormulaL10n.string("surface.enter_b") }
    /// B 面 → 返回 A 面
    static var returnALabel: String { FormulaL10n.string("surface.return_a") }
}
