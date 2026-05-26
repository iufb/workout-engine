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
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        RootTabView()
            .environment(\.locale, settings.resolvedLocale)
            .preferredColorScheme(settings.resolvedColorScheme)
            .tint(AppColors.accent)
    }
}
