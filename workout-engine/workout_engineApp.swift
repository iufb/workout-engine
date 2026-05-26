import SwiftData
import SwiftUI

@main
struct workout_engineApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerProvider.make()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct AppRootView: View {
    var body: some View {
        RootTabView()
            .environment(\.locale, AppSettings.shared.resolvedLocale)
    }
}
