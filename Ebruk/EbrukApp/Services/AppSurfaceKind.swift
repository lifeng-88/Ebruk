import Foundation

/// 应用内 A/B/C 面；与 `/v1/app_config.type` 的映射见 `from(appConfigType:)`。
enum AppSurfaceKind: Equatable {
    case a
    /// Velo 原生壳
    case b
    /// WebView H5
    case c

    /// 服务端 `app_config.type` → 面：**1** A · **2** C（WebView） · **3** B（Velo）
    static func from(appConfigType type: Int) -> AppSurfaceKind? {
        switch type {
        case 1: return .a
        case 2: return .c
        case 3: return .b
        default: return nil
        }
    }

    /// 面 → 服务端 `app_config.type`
    var appConfigType: Int {
        switch self {
        case .a: return 1
        case .c: return 2
        case .b: return 3
        }
    }

    var logLabel: String {
        switch self {
        case .a: return "A面"
        case .b: return "B面"
        case .c: return "C面"
        }
    }
}
