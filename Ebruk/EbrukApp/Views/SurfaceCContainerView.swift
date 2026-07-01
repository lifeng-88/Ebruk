import SwiftUI

/// C 面：全屏 H5 WebView（Bridge / 媒体缓存 / IAP / 推送），对齐 Hub `HubCFaceWebHost`。
struct SurfaceCContainerView: View {
    @ObservedObject private var surface = AppSurfaceController.shared

    var body: some View {
        if let pageURL = surface.surfaceWebURL ?? SurfaceCConfig.resolveURL(remoteURLString: nil) {
            SurfaceCWebHostContent(pageURL: pageURL)
        } else {
            missingURLState
        }
    }

    private var missingURLState: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.5))
            Text("C 面 H5 地址未配置")
                .font(.headline)
                .foregroundStyle(.white)
            Button("返回 A 面") { surface.showSurfaceA() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct SurfaceCWebHostContent: View {
    @ObservedObject private var surface = AppSurfaceController.shared
    let pageURL: URL
    @StateObject private var webViewModel: SurfaceCH5WebViewModel
    @State private var secretTapCount = 0
    @State private var resetTask: Task<Void, Never>?

    init(pageURL: URL) {
        self.pageURL = pageURL
        _webViewModel = StateObject(wrappedValue: SurfaceCH5WebViewModel(pageURL: pageURL))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.ignoresSafeArea()

            SurfaceCH5WebView(viewModel: webViewModel)
                .opacity(webViewModel.isReady ? 1 : 0)
                .ignoresSafeArea(edges: .bottom)

            if !webViewModel.isReady, webViewModel.errorMessage == nil {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }

            if let errorMessage = webViewModel.errorMessage {
                loadErrorOverlay(errorMessage)
            }

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
            .padding(.bottom, 20)
            #else
            Color.clear
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
                .onTapGesture { registerExitTap() }
                .padding(.leading, 8)
                .padding(.bottom, 16)
            #endif
        }
    }

    private func loadErrorOverlay(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("重试") {
                webViewModel.reload()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.72))
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
