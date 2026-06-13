import SwiftUI

@main
struct EbrukApp: App {
    @UIApplicationDelegateAdaptor(VeloApplicationDelegate.self) private var applicationDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
