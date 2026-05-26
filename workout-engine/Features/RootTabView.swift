import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case home
    case editor
    case settings
}

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var editorPresetID: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
                editorPresetID: $editorPresetID
            )
            .tabItem {
                Label(L10n.t("Тренировка"), systemImage: "figure.run")
            }
            .tag(AppTab.home)

            PresetEditorView(presetIDToLoad: $editorPresetID)
                .tabItem {
                    Label(L10n.t("Конструктор"), systemImage: "slider.horizontal.3")
                }
                .tag(AppTab.editor)

            SettingsView()
                .tabItem {
                    Label(L10n.t("Настройки"), systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
}
