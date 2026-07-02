import SwiftUI
import UIKit

/// 与 `LaunchScreen.storyboard` 视觉一致的首屏加载页（bootstrap 完成前展示）。
struct AppLaunchLoadingView: View {
    var body: some View {
        ZStack {
            launchImage
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.15),
                    Color(red: 0.10, green: 0.04, blue: 0.18).opacity(0.72)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Text("Ebruk")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.05)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                    .padding(.bottom, 48)
            }
        }
        .background(Color(red: 0.10, green: 0.04, blue: 0.18).ignoresSafeArea())
    }

    /// 与 Launch Screen 相同：使用 Bundle 内 `LaunchScreenLogo`（@1x/@2x/@3x PNG）。
    private var launchImage: Image {
        if let uiImage = UIImage(named: "LaunchScreenLogo") {
            return Image(uiImage: uiImage)
        }
        return Image("LaunchSplash")
    }
}
