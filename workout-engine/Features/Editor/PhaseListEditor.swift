import SwiftUI

struct PhaseListEditor: View {
    @Binding var phases: [PresetPhaseItem]
    @Binding var showAddPhaseSheet: Bool
    @Binding var isReordering: Bool

    @State private var draggingID: UUID?
    @State private var dragTranslation: CGFloat = 0
    @State private var dragStartCenterY: CGFloat = 0
    @State private var dragStartWidth: CGFloat = 0
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var reorderHapticTrigger = false

    init(
        phases: Binding<[PresetPhaseItem]>,
        showAddPhaseSheet: Binding<Bool>,
        isReordering: Binding<Bool> = .constant(false)
    ) {
        _phases = phases
        _showAddPhaseSheet = showAddPhaseSheet
        _isReordering = isReordering
    }

    var body: some View {
        VStack(spacing: EditorTheme.sectionSpacing) {
            ForEach($phases) { $phase in
                phaseRow(phase: $phase)
                    .frame(maxHeight: draggingID == phase.id ? 0 : nil, alignment: .top)
                    .clipped()
                    .anchorPreference(
                        key: PhaseRowBoundsPreference.self,
                        value: .bounds
                    ) { anchor in
                        [phase.id: anchor]
                    }
            }

            addPhaseButton
        }
        .coordinateSpace(name: EditorTheme.phaseReorderCoordinateSpace)
        .backgroundPreferenceValue(PhaseRowBoundsPreference.self) { anchors in
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: PhaseRowFramesPreference.self,
                        value: anchors.mapValues { proxy[$0] }
                    )
            }
        }
        .onPreferenceChange(PhaseRowFramesPreference.self) { frames in
            rowFrames = frames
        }
        .overlayPreferenceValue(PhaseRowBoundsPreference.self) { anchors in
            dragOverlay(anchors: anchors)
        }
        .animation(EditorTheme.phaseReorderAnimation, value: phases.map(\.id))
        .sensoryFeedback(.selection, trigger: reorderHapticTrigger)
    }

    @ViewBuilder
    private func phaseRow(phase: Binding<PresetPhaseItem>) -> some View {
        let item = phase.wrappedValue

        SwipeDeleteRow(
            canDelete: phases.count > 1 && draggingID == nil,
            onDelete: { deletePhase(id: item.id) }
        ) {
            PhaseCardView(
                phase: phase,
                phaseIndex: phaseIndex(for: item.id),
                phaseCount: phases.count,
                isDragging: draggingID == item.id,
                onDragChanged: { value in
                    handleDragChanged(for: item, value: value)
                },
                onDragEnded: endDrag
            )
        }
    }

    @ViewBuilder
    private func dragOverlay(anchors: [UUID: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            if let draggingID,
               let phase = phases.first(where: { $0.id == draggingID }) {
                let width = dragStartWidth > 0
                    ? dragStartWidth
                    : anchors[draggingID].map { proxy[$0].width } ?? proxy.size.width

                PhaseCardDragPreview(phase: phase)
                    .frame(width: width)
                    .position(
                        x: proxy.size.width / 2,
                        y: dragStartCenterY + dragTranslation
                    )
                    .allowsHitTesting(false)
                    .transition(.identity)
            }
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

    private func phaseIndex(for id: UUID) -> Int {
        (phases.firstIndex(where: { $0.id == id }) ?? 0) + 1
    }

    private func deletePhase(id: UUID) {
        guard phases.count > 1 else { return }
        withAnimation(EditorTheme.phaseReorderAnimation) {
            phases.removeAll { $0.id == id }
        }
    }

    private func handleDragChanged(for item: PresetPhaseItem, value: DragGesture.Value) {
        if draggingID == nil {
            guard let frame = rowFrames[item.id] else { return }
            draggingID = item.id
            dragStartCenterY = frame.midY
            dragStartWidth = frame.width
            dragTranslation = 0
            isReordering = true
        }

        guard draggingID == item.id else { return }

        dragTranslation = value.translation.height
        let dragCenterY = dragStartCenterY + dragTranslation

        guard let targetIndex = PhaseReorder.targetIndex(
            dragCenterY: dragCenterY,
            draggedID: item.id,
            in: phases,
            rowFrames: rowFrames
        ) else { return }

        withAnimation(EditorTheme.phaseReorderAnimation) {
            if PhaseReorder.moveToIndex(phases: &phases, draggedID: item.id, to: targetIndex) {
                reorderHapticTrigger.toggle()
            }
        }
    }

    private func endDrag() {
        withAnimation(EditorTheme.phaseReorderAnimation) {
            draggingID = nil
            dragTranslation = 0
            dragStartCenterY = 0
            dragStartWidth = 0
            isReordering = false
        }
    }
}

private struct PhaseRowBoundsPreference: PreferenceKey {
    static var defaultValue: [UUID: Anchor<CGRect>] = [:]

    static func reduce(value: inout [UUID: Anchor<CGRect>], nextValue: () -> [UUID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct PhaseRowFramesPreference: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview {
    @Previewable @State var phases = WorkoutPreset.defaultNew().phases
    @Previewable @State var showSheet = false
    @Previewable @State var isReordering = false
    ScrollView {
        PhaseListEditor(
            phases: $phases,
            showAddPhaseSheet: $showSheet,
            isReordering: $isReordering
        )
        .padding(.horizontal, 20)
    }
    .scrollDisabled(isReordering)
}
