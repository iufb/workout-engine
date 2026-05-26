import SwiftUI

/// Phase rows for the editor `List` (swipe-to-delete + custom drag reorder).
struct PhaseListEditor: View {
    @Binding var phases: [PresetPhaseItem]
    @Binding var isReordering: Bool

    @State private var draggingID: UUID?
    @State private var dragTranslation: CGFloat = 0
    @State private var dragStartCenterY: CGFloat = 0
    @State private var dragStartWidth: CGFloat = 0
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var reorderHapticTrigger = false

    private var listRowInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
    }

    var body: some View {
        Group {
            ForEach($phases) { $phase in
                phaseRow(phase: $phase)
            }
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
        let canSwipeDelete = phases.count > 1 && draggingID == nil

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
        .frame(maxHeight: draggingID == item.id ? 0 : nil, alignment: .top)
        .clipped()
        .listRowInsets(listRowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .anchorPreference(key: PhaseRowBoundsPreference.self, value: .bounds) { anchor in
            [item.id: anchor]
        }
        .modifier(PhaseSwipeDeleteModifier(canDelete: canSwipeDelete) {
            deletePhase(id: item.id)
        })
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

private struct PhaseSwipeDeleteModifier: ViewModifier {
    let canDelete: Bool
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        if canDelete {
            content.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: onDelete) {
                    Label(String(localized: "Удалить"), systemImage: "trash")
                }
            }
        } else {
            content
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
    @Previewable @State var isReordering = false
    List {
        PhaseListEditor(phases: $phases, isReordering: $isReordering)
    }
    .listStyle(.plain)
    .scrollDisabled(isReordering)
}
