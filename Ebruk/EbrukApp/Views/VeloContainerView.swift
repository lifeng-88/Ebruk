import AVFoundation
import SwiftUI

struct VeloContainerView: View {
    @ObservedObject private var surface = AppSurfaceController.shared
    @StateObject private var wallet = UserWalletStore()
    @StateObject private var tabRouter = AppTabRouter()
    @StateObject private var auth = AuthSessionStore()
    @StateObject private var versionConfig = VersionConfigStore()
    @StateObject private var appLanguage = AppLanguageStore()
    @State private var secretTapCount = 0
    @State private var resetTask: Task<Void, Never>?

    init() {
        VeloNavigationChrome.applyGlobalTint()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {}
    }

    private var surfaceSwitchBottomPadding: CGFloat {
        tabRouter.shouldHideTabBar ? 16 : MainTabBarMetrics.estimatedContentHeight + 12
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VeloRootView()
                .environmentObject(wallet)
                .environmentObject(tabRouter)
                .environmentObject(auth)
                .environmentObject(versionConfig)
                .environmentObject(appLanguage)
                .environment(\.locale, appLanguage.effectiveLocale)

            #if DEBUG
            Button {
                surface.showSurfaceA()
            } label: {
                Text(AppSurfaceCopy.returnALabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.leading, 12)
            .padding(.bottom, surfaceSwitchBottomPadding)
            #else
            Color.clear
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
                .onTapGesture { registerExitTap() }
                .padding(.leading, 8)
                .padding(.bottom, surfaceSwitchBottomPadding)
            #endif
        }
        .preferredColorScheme(.dark)
    }

    private func registerExitTap() {
        secretTapCount += 1
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            secretTapCount = 0
        }
        guard secretTapCount >= 7 else { return }
        secretTapCount = 0
        resetTask?.cancel()
        surface.showSurfaceA()
    }
}
