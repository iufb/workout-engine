import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var presets: [WorkoutPreset] = []
    @State private var loadError: String?
    @State private var selectedPreset: WorkoutPreset?
    @State private var coordinator = WorkoutSessionCoordinator()

    var body: some View {
        NavigationStack {
            List {
                if let tabata = presets.first(where: { $0.isBuiltIn }) {
                    Section(String(localized: "Быстрый старт")) {
                        Button {
                            selectedPreset = tabata
                        } label: {
                            QuickStartCard(preset: tabata)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(String(localized: "Мои интервалы")) {
                    if presets.filter({ !$0.isBuiltIn }).isEmpty {
                        Text(String(localized: "Создайте интервал во вкладке «Конструктор»"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(presets.filter { !$0.isBuiltIn }) { preset in
                            Button {
                                selectedPreset = preset
                            } label: {
                                PresetRow(preset: preset)
                            }
                        }
                        .onDelete(perform: deleteCustomPresets)
                    }
                }
            }
            .navigationTitle(String(localized: "Тренировка"))
            .navigationDestination(item: $selectedPreset) { preset in
                ActiveWorkoutView(coordinator: coordinator, preset: preset)
            }
            .task { await reload() }
            .refreshable { await reload() }
            .alert(String(localized: "Ошибка"), isPresented: .constant(loadError != nil)) {
                Button(String(localized: "OK")) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    private func reload() async {
        do {
            let store = PresetStore(modelContext: modelContext)
            try store.seedDefaultsIfNeeded()
            presets = try store.fetchAll()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func deleteCustomPresets(at offsets: IndexSet) {
        let custom = presets.filter { !$0.isBuiltIn }
        let store = PresetStore(modelContext: modelContext)
        for index in offsets {
            let preset = custom[index]
            try? store.delete(preset)
        }
        Task { await reload() }
    }
}

private struct QuickStartCard: View {
    let preset: WorkoutPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(preset.name)
                .font(.title2.bold())
            Text(intervalSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(localized: "Старт →"))
                .font(.headline)
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var intervalSummary: String {
        String(
            localized: "\(preset.phaseCount) фаз · ~\(TimeFormatting.durationLabel(preset.estimatedTotalDuration))"
        )
    }
}

private struct PresetRow: View {
    let preset: WorkoutPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preset.name)
                .font(.headline)
            Text(
                String(
                    localized: "\(preset.phaseCount) фаз · ~\(TimeFormatting.durationLabel(preset.estimatedTotalDuration))"
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
}
