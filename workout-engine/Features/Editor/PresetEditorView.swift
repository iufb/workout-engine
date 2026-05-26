import SwiftData
import SwiftUI

struct PresetEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredPreset.name) private var storedPresets: [StoredPreset]
    @Binding var presetIDToLoad: UUID?

    @State private var editingPresetID: UUID?
    @State private var name = ""
    @State private var phases: [PresetPhaseItem] = WorkoutPreset.defaultNew().phases
    @State private var roundCount = WorkoutPreset.defaultNew().roundCount
    @State private var saveMessage: String?
    @State private var showSaveToast = false
    @State private var showAddPhaseSheet = false
    @State private var saveTrigger = false
    @State private var isPhaseReordering = false
    @State private var phaseReorderSession = PhaseListReorderSession()
    @State private var roundStepperHapticTrigger = false
    @State private var didSeedDefaults = false
    @State private var pendingPresetSwitch: WorkoutPreset?
    @State private var showUnsavedChangesDialog = false
    @State private var showDeleteConfirmation = false
    @FocusState private var focusedField: EditorFocusField?

    private var savedPresets: [WorkoutPreset] {
        storedPresets.map { $0.toWorkoutPreset() }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(L10n.t("Название интервала"), text: $name)
                        .font(.title2.weight(.semibold))
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .presetName)
                        .listRowInsets(EditorTheme.listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    PresetSummaryCard(
                        totalDuration: draftPreset.estimatedTotalDuration,
                        cyclePhases: phases,
                        roundCount: roundCount
                    )
                    .editorCard()
                    .listRowInsets(EditorTheme.listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onTapGesture {
                        dismissEditorKeyboard(focusedField: $focusedField)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.t("Количество кругов"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismissEditorKeyboard(focusedField: $focusedField)
                            }

                        roundCountRow
                    }
                    .listRowInsets(EditorTheme.listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                Section {
                    ForEach($phases) { $phase in
                        PhaseListRow(
                            phase: $phase,
                            phases: $phases,
                            session: phaseReorderSession,
                            isReordering: $isPhaseReordering,
                            editorFocus: $focusedField
                        )
                        .transaction { transaction in
                            if phaseReorderSession.draggingID != nil {
                                transaction.disablesAnimations = true
                            }
                        }
                    }
                } header: {
                    Text(L10n.t("Круг"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissEditorKeyboard(focusedField: $focusedField)
                        }
                        .textCase(nil)
                }

                Section {
                    addPhaseButton
                        .listRowInsets(EditorTheme.listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, EditorTheme.horizontalPadding, for: .scrollContent)
            .safeAreaPadding(.bottom, EditorTheme.scrollBottomPadding)
            .phaseListReorderSupport(phases: $phases, session: phaseReorderSession)
            .scrollDisabled(isPhaseReordering)
            .background(EditorTheme.groupedBackground)
            .navigationTitle(L10n.t("Конструктор"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                EditorSaveBar(
                    canSave: canSave,
                    validationHint: validationHint,
                    onSave: save
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
            .task { await seedAndLoadInitialPreset() }
            .onChange(of: presetIDToLoad) { _, newID in
                guard let newID else { return }
                loadPresetFromHome(id: newID)
                presetIDToLoad = nil
            }
            .confirmationDialog(
                L10n.t("Несохранённые изменения"),
                isPresented: $showUnsavedChangesDialog,
                titleVisibility: .visible
            ) {
                Button(L10n.t("Не сохранять"), role: .destructive) {
                    if let pending = pendingPresetSwitch {
                        apply(preset: pending)
                    } else {
                        startNewPreset()
                    }
                    pendingPresetSwitch = nil
                }
                Button(L10n.t("Отмена"), role: .cancel) {
                    pendingPresetSwitch = nil
                }
            } message: {
                Text(L10n.t("Изменения в текущем интервале будут потеряны."))
            }
            .confirmationDialog(
                L10n.t("Удалить интервал?"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.t("Удалить"), role: .destructive) {
                    deleteCurrentPreset()
                }
                Button(L10n.t("Отмена"), role: .cancel) {}
            } message: {
                Text(L10n.t("Интервал «\(name)» будет удалён без возможности восстановления."))
            }
            .sensoryFeedback(.success, trigger: saveTrigger)
            .sensoryFeedback(.selection, trigger: roundStepperHapticTrigger)
        }
    }

    private var roundCountRow: some View {
        HStack {
            Text(RoundsFormatting.label(count: roundCount))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            RoundCountStepper(
                count: $roundCount,
                range: WorkoutPreset.minRoundCount ... WorkoutPreset.maxRoundCount,
                onAdjust: {
                    dismissEditorKeyboard(focusedField: $focusedField)
                    roundStepperHapticTrigger.toggle()
                }
            )
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.t("Количество кругов, \(roundCount)"))
    }

    private var addPhaseButton: some View {
        Button {
            dismissEditorKeyboard(focusedField: $focusedField)
            showAddPhaseSheet = true
        } label: {
            Label(L10n.t("Добавить фазу"), systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .background {
            RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(AppColors.accent.opacity(0.45))
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if savedPresets.count > 1 {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    ForEach(savedPresets) { preset in
                        Button(preset.name) {
                            requestApply(preset: preset)
                        }
                    }
                } label: {
                    Label(currentPresetTitle, systemImage: "list.bullet")
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    requestStartNewPreset()
                } label: {
                    Label(L10n.t("Новый"), systemImage: "plus")
                }

                if canDeleteCurrentPreset {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(L10n.t("Удалить интервал"), systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private var currentPresetTitle: String {
        if let id = editingPresetID,
           let preset = savedPresets.first(where: { $0.id == id }) {
            return preset.name
        }
        return name.isEmpty ? L10n.t("Новый интервал") : name
    }

    private var draftPreset: WorkoutPreset {
        WorkoutPreset(
            id: editingPresetID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? L10n.t("Интервал")
                : name,
            phases: phases,
            roundCount: roundCount
        )
    }

    private var canSave: Bool {
        validationHint == nil
    }

    private var canDeleteCurrentPreset: Bool {
        guard let id = editingPresetID,
              let preset = savedPresets.first(where: { $0.id == id }) else { return false }
        return !preset.isBuiltIn
    }

    private var validationHint: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return L10n.t("Введите название")
        }
        if phases.isEmpty {
            return L10n.t("Добавьте хотя бы одну фазу")
        }
        if phases.contains(where: { !DurationParsing.allowedRange(for: $0.kind).contains($0.durationSeconds) }) {
            return L10n.t("Проверьте длительность фаз")
        }
        return nil
    }

    private var hasUnsavedChanges: Bool {
        guard let id = editingPresetID,
              let saved = savedPresets.first(where: { $0.id == id }) else {
            let defaultPreset = WorkoutPreset.defaultNew()
            return name != defaultPreset.name
                || phases != defaultPreset.phases
                || roundCount != defaultPreset.roundCount
        }
        let draft = draftPreset.normalized()
        let baseline = saved.normalized()
        return draft.name != baseline.name
            || draft.phases != baseline.phases
            || draft.roundCount != baseline.roundCount
    }

    private func seedAndLoadInitialPreset() async {
        guard !didSeedDefaults else { return }
        didSeedDefaults = true
        do {
            let store = PresetStore(modelContext: modelContext)
            try store.seedDefaultsIfNeeded()
        } catch {
            startNewPreset()
            return
        }

        if let id = editingPresetID, savedPresets.contains(where: { $0.id == id }) {
            return
        }
        if let first = savedPresets.first {
            apply(preset: first)
        } else {
            startNewPreset()
        }
    }

    private func loadPresetFromHome(id: UUID) {
        guard let preset = savedPresets.first(where: { $0.id == id }) else { return }
        requestApply(preset: preset)
    }

    private func requestStartNewPreset() {
        dismissEditorKeyboard(focusedField: $focusedField)
        guard hasUnsavedChanges else {
            startNewPreset()
            return
        }
        pendingPresetSwitch = nil
        showUnsavedChangesDialog = true
    }

    private func requestApply(preset: WorkoutPreset) {
        dismissEditorKeyboard(focusedField: $focusedField)
        if preset.id == editingPresetID, !hasUnsavedChanges { return }
        guard hasUnsavedChanges else {
            apply(preset: preset)
            return
        }
        pendingPresetSwitch = preset
        showUnsavedChangesDialog = true
    }

    private func startNewPreset() {
        dismissEditorKeyboard(focusedField: $focusedField)
        withAnimation(.snappy) {
            let preset = WorkoutPreset.defaultNew()
            editingPresetID = nil
            name = preset.name
            phases = preset.phases
            roundCount = preset.roundCount
        }
    }

    private func apply(preset: WorkoutPreset) {
        dismissEditorKeyboard(focusedField: $focusedField)
        withAnimation(.snappy) {
            editingPresetID = preset.id
            name = preset.name
            phases = preset.phases
            roundCount = preset.roundCount
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
            roundCount = preset.roundCount
            saveMessage = L10n.t("Интервал «\(preset.name)» сохранён")
            presentSaveToast()
            saveTrigger.toggle()
        } catch {
            saveMessage = error.localizedDescription
            presentSaveToast()
        }
    }

    private func deleteCurrentPreset() {
        guard let id = editingPresetID,
              let preset = savedPresets.first(where: { $0.id == id }) else { return }
        let store = PresetStore(modelContext: modelContext)
        try? store.delete(preset)
        if AppSettings.shared.lastUsedPresetID == id {
            AppSettings.shared.lastUsedPresetID = nil
        }
        if let first = savedPresets.first(where: { $0.id != id }) {
            apply(preset: first)
        } else {
            startNewPreset()
        }
    }

    private func presentSaveToast() {
        showSaveToast = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            showSaveToast = false
        }
    }
}

#Preview("Light") {
    @Previewable @State var presetID: UUID?
    PresetEditorView(presetIDToLoad: $presetID)
        .modelContainer(for: StoredPreset.self, inMemory: true)
}

#Preview("Dark") {
    @Previewable @State var presetID: UUID?
    PresetEditorView(presetIDToLoad: $presetID)
        .modelContainer(for: StoredPreset.self, inMemory: true)
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    @Previewable @State var presetID: UUID?
    PresetEditorView(presetIDToLoad: $presetID)
        .modelContainer(for: StoredPreset.self, inMemory: true)
        .dynamicTypeSize(.accessibility2)
}
