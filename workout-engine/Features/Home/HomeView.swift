import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredPreset.name) private var storedPresets: [StoredPreset]
    @Binding var selectedTab: AppTab
    @Binding var editorPresetID: UUID?

    @State private var loadError: String?
    @State private var selectedPreset: WorkoutPreset?
    @State private var coordinator = WorkoutSessionCoordinator()
    @State private var startHapticTrigger = false
    @State private var didSeedDefaults = false

    private var presets: [WorkoutPreset] {
        storedPresets.map { $0.toWorkoutPreset() }
    }

    private var quickStartPreset: WorkoutPreset? {
        QuickStartResolver.resolve(
            presets: presets,
            lastUsedID: AppSettings.shared.lastUsedPresetID
        )
    }

    private var listRowInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
    }

    var body: some View {
        NavigationStack {
            List {
                if let quickStartPreset {
                    Section {
                        quickStartRow(preset: quickStartPreset)
                            .listRowInsets(listRowInsets)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }

                Section {
                    if presets.isEmpty {
                        WorkoutEmptyPresetsHint {
                            editorPresetID = nil
                            selectedTab = .editor
                        }
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(presets) { preset in
                            presetRow(preset: preset)
                        }
                    }
                } header: {
                    Text(L10n.t("Мои интервалы"))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(WorkoutTheme.groupedBackground)
            .contentMargins(.horizontal, WorkoutTheme.horizontalPadding, for: .scrollContent)
            .navigationTitle(L10n.t("Тренировка"))
            .navigationDestination(item: $selectedPreset) { preset in
                ActiveWorkoutView(coordinator: coordinator, preset: preset)
            }
            .task { await seedDefaultsIfNeeded() }
            .alert(L10n.t("Ошибка"), isPresented: .constant(loadError != nil)) {
                Button(L10n.t("OK")) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
            .sensoryFeedback(.selection, trigger: startHapticTrigger)
        }
    }

    @ViewBuilder
    private func quickStartRow(preset: WorkoutPreset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("Быстрый старт"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Button {
                startHapticTrigger.toggle()
                selectedPreset = preset
            } label: {
                WorkoutQuickStartCard(
                    preset: preset,
                    showsLastUsedBadge: QuickStartResolver.isLastUsed(
                        preset: preset,
                        lastUsedID: AppSettings.shared.lastUsedPresetID
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func presetRow(preset: WorkoutPreset) -> some View {
        Button {
            startHapticTrigger.toggle()
            selectedPreset = preset
        } label: {
            WorkoutPresetCard(preset: preset)
        }
        .buttonStyle(.plain)
        .listRowInsets(listRowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deletePreset(preset)
            } label: {
                Label(L10n.t("Удалить"), systemImage: "trash")
            }
            .tint(AppColors.destructive)
        }
        .swipeActions(edge: .leading) {
            Button {
                openEditor(for: preset)
            } label: {
                Label(L10n.t("Изменить"), systemImage: "pencil")
            }
            .tint(AppColors.accent)
        }
    }

    private func openEditor(for preset: WorkoutPreset) {
        editorPresetID = preset.id
        selectedTab = .editor
    }

    private func seedDefaultsIfNeeded() async {
        guard !didSeedDefaults else { return }
        didSeedDefaults = true
        do {
            let store = PresetStore(modelContext: modelContext)
            try store.seedDefaultsIfNeeded()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func deletePreset(_ preset: WorkoutPreset) {
        withAnimation(.snappy) {
            let store = PresetStore(modelContext: modelContext)
            try? store.delete(preset)
            if AppSettings.shared.lastUsedPresetID == preset.id {
                AppSettings.shared.lastUsedPresetID = nil
            }
        }
    }
}

#Preview {
    @Previewable @State var tab = AppTab.home
    @Previewable @State var editorID: UUID?
    HomeView(selectedTab: $tab, editorPresetID: $editorID)
        .modelContainer(for: StoredPreset.self, inMemory: true)
}
