import SwiftData
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(localized: "Тренировка"), systemImage: "figure.run")
                }

            PresetEditorView()
                .tabItem {
                    Label(String(localized: "Конструктор"), systemImage: "slider.horizontal.3")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "Настройки"), systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
}
