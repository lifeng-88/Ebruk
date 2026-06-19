import SwiftUI

struct AppRootView: View {
    @ObservedObject private var surface = AppSurfaceController.shared

    var body: some View {
        Group {
            if surface.isBootstrapComplete {
                if surface.isSurfaceB {
                    VeloContainerView()
                } else {
                    MainTabView()
                }
            } else {
                AppLaunchLoadingView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: surface.isSurfaceB)
        .animation(.easeInOut(duration: 0.2), value: surface.isBootstrapComplete)
        .task {
            await surface.bootstrapFromRemote()
        }
    }
}

private struct AppLaunchLoadingView: View {
    var body: some View {
        ZStack {
            Image("LaunchSplash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()
                ProgressView()
                    .tint(.white)
                    .padding(.bottom, 56)
            }
        }
    }
}
