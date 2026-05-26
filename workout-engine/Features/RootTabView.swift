import SwiftData
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(L10n.t("Тренировка"), systemImage: "figure.run")
                }

            PresetEditorView()
                .tabItem {
                    Label(L10n.t("Конструктор"), systemImage: "slider.horizontal.3")
                }

            SettingsView()
                .tabItem {
                    Label(L10n.t("Настройки"), systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
}
