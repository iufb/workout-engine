import SwiftData
import SwiftUI

@main
struct workout_engineApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerProvider.make()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
