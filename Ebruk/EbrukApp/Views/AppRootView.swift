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
