import SwiftUI

struct AppRootView: View {
    @ObservedObject private var surface = AppSurfaceController.shared

    var body: some View {
        Group {
            if surface.isBootstrapComplete {
                switch surface.activeSurface {
                case .a:
                    MainTabView()
                case .b:
                    VeloContainerView()
                case .c:
                    SurfaceCContainerView()
                }
            } else {
                AppLaunchLoadingView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: surface.activeSurface)
        .animation(.easeInOut(duration: 0.2), value: surface.isBootstrapComplete)
        .task {
            await surface.bootstrapFromRemote()
        }
    }
}

private struct AppLaunchLoadingView: View {
    private let iconSize: CGFloat = 136

    var body: some View {
        ZStack {
            Color("LaunchBackground", bundle: .main)
                .ignoresSafeArea()

            Image("LaunchScreenLogo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)

            VStack {
                Spacer()
                ProgressView()
                    .tint(.white)
                    .padding(.bottom, 56)
            }
        }
    }
}
