import SwiftUI

@main
struct LaunchPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchPreview()
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}

private struct LaunchPreview: View {
    @StateObject private var model = SplashViewModel()
    @State private var showDestination = false

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.08).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("UltraStore")
                    .font(.largeTitle.bold())
                Text("Launch animation preview")
                    .foregroundStyle(.secondary)
                Text("Main interface placeholder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SplashView(viewModel: model) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showDestination = true
                }
            }
            .opacity(showDestination ? 0 : 1)
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                model.isReadyToExit = true
            } catch {
                // The preview was closed before playback.
            }
        }
    }
}
