import Foundation

@Observable
@MainActor
final class UserStore {
    private(set) var userID: String

    private let userIDKey = "diy_formula_user_id"

    init() {
        if let saved = UserDefaults.standard.string(forKey: userIDKey), !saved.isEmpty {
            userID = saved
        } else {
            let suffix = UUID().uuidString
                .replacingOccurrences(of: "-", with: "")
                .prefix(8)
                .uppercased()
            userID = "DF-\(suffix)"
            UserDefaults.standard.set(userID, forKey: userIDKey)
        }
    }
}
