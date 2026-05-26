import SwiftData
import SwiftUI

struct PresetEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var editingPresetID: UUID?
    @State private var savedPresets: [WorkoutPreset] = []
    @State private var name = ""
    @State private var phases: [PresetPhaseItem] = WorkoutPreset.defaultNew().phases
    @State private var isBuiltIn = false
    @State private var saveMessage: String?
    @State private var showSaveToast = false
    @State private var showAddPhaseSheet = false
    @State private var saveTrigger = false
    @State private var isPhaseReordering = false

    private var listRowInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(String(localized: "Название интервала"), text: $name)
                        .font(.title2.weight(.semibold))
                        .textFieldStyle(.plain)
                        .padding(.vertical, 4)
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    PresetSummaryCard(
                        totalDuration: draftPreset.estimatedTotalDuration,
                        phases: phases
                    )
                    .editorCard()
                    .listRowInsets(listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                Section {
                    PhaseListEditor(phases: $phases, isReordering: $isPhaseReordering)
                }

                Section {
                    addPhaseButton
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(isPhaseReordering)
            .background(EditorTheme.groupedBackground)
            .contentMargins(.horizontal, EditorTheme.horizontalPadding, for: .scrollContent)
            .navigationTitle(String(localized: "Конструктор"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                EditorSaveBar(
                    canSave: canSave,
                    validationHint: validationHint,
                    showsTabataReset: isBuiltIn,
                    onSave: save,
                    onResetTabata: resetTabata
                )
            }
            .overlay(alignment: .top) {
                if showSaveToast, let saveMessage {
                    SaveToastView(message: saveMessage)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: showSaveToast)
            .sheet(isPresented: $showAddPhaseSheet) {
                AddPhaseSheet { kind in
                    addPhase(kind: kind)
                }
            }
            .task { await loadPresets() }
            .sensoryFeedback(.success, trigger: saveTrigger)
        }
    }

    private var addPhaseButton: some View {
        Button {
            showAddPhaseSheet = true
        } label: {
            Label(String(localized: "Добавить фазу"), systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .background {
            RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(Color.accentColor.opacity(0.45))
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if savedPresets.count > 1 {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    ForEach(savedPresets) { preset in
                        Button(preset.name) {
                            apply(preset: preset)
                        }
                    }
                } label: {
                    Label(currentPresetTitle, systemImage: "list.bullet")
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                startNewPreset()
            } label: {
                Label(String(localized: "Новый"), systemImage: "plus")
            }
        }
    }

    private var currentPresetTitle: String {
        if let id = editingPresetID,
           let preset = savedPresets.first(where: { $0.id == id }) {
            return preset.name
        }
        return name.isEmpty ? String(localized: "Новый интервал") : name
    }

    private var draftPreset: WorkoutPreset {
        WorkoutPreset(
            id: editingPresetID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? String(localized: "Интервал")
                : name,
            phases: phases,
            isBuiltIn: isBuiltIn
        )
    }

    private var canSave: Bool {
        validationHint == nil
    }

    private var validationHint: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(localized: "Введите название")
        }
        if phases.isEmpty {
            return String(localized: "Добавьте хотя бы одну фазу")
        }
        if phases.contains(where: { !DurationParsing.allowedRange(for: $0.kind).contains($0.durationSeconds) }) {
            return String(localized: "Проверьте длительность фаз")
        }
        return nil
    }

    private func loadPresets() async {
        do {
            let store = PresetStore(modelContext: modelContext)
            try store.seedDefaultsIfNeeded()
            savedPresets = try store.fetchAll()
            if let id = editingPresetID, savedPresets.contains(where: { $0.id == id }) {
                return
            }
            if let first = savedPresets.first {
                apply(preset: first)
            } else {
                startNewPreset()
            }
        } catch {
            startNewPreset()
        }
    }

    private func startNewPreset() {
        withAnimation(.snappy) {
            let preset = WorkoutPreset.defaultNew()
            editingPresetID = nil
            isBuiltIn = false
            name = preset.name
            phases = preset.phases
        }
    }

    private func apply(preset: WorkoutPreset) {
        withAnimation(.snappy) {
            editingPresetID = preset.id
            isBuiltIn = preset.isBuiltIn
            name = preset.name
            phases = preset.phases
        }
    }

    private func addPhase(kind: PhaseKind) {
        withAnimation(.snappy) {
            phases.append(PresetPhaseItem.make(kind: kind))
        }
    }

    private func save() {
        let preset = draftPreset.normalized()
        do {
            let store = PresetStore(modelContext: modelContext)
            try store.save(preset)
            editingPresetID = preset.id
            isBuiltIn = preset.isBuiltIn
            savedPresets = try store.fetchAll()
            saveMessage = preset.isBuiltIn
                ? String(localized: "Пресет Tabata обновлён")
                : String(localized: "Интервал «\(preset.name)» сохранён")
            presentSaveToast()
            saveTrigger.toggle()
        } catch {
            saveMessage = error.localizedDescription
            presentSaveToast()
        }
    }

    private func presentSaveToast() {
        showSaveToast = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            showSaveToast = false
        }
    }

    private func resetTabata() {
        apply(preset: .tabata)
        do {
            let store = PresetStore(modelContext: modelContext)
            try store.resetTabataToDefault()
            try store.save(.tabata)
            savedPresets = try store.fetchAll()
        } catch {}
    }
}

#Preview("Light") {
    PresetEditorView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
}

#Preview("Dark") {
    PresetEditorView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    PresetEditorView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
        .dynamicTypeSize(.accessibility2)
}
