import SwiftUI

@MainActor
@Observable
final class PhaseListReorderSession {
    var draggingID: UUID?
    var dragTranslation: CGFloat = 0
    var dragStartCenterY: CGFloat = 0
    var dragStartWidth: CGFloat = 0
    var rowFrames: [UUID: CGRect] = [:]
    /// Stable layout snapshot for hit-testing while `List` relayouts during drag.
    private var layoutRowFrames: [UUID: CGRect] = [:]
    var reorderHapticTrigger = false

    func updateRowFrames(_ frames: [UUID: CGRect]) {
        rowFrames = frames
        if draggingID == nil {
            layoutRowFrames = frames
        }
    }

    func phaseIndex(for id: UUID, in phases: [PresetPhaseItem]) -> Int {
        (phases.firstIndex(where: { $0.id == id }) ?? 0) + 1
    }

    func handleDragChanged(
        for item: PresetPhaseItem,
        value: DragGesture.Value,
        phases: Binding<[PresetPhaseItem]>,
        isReordering: Binding<Bool>
    ) {
        if draggingID == nil {
            guard let frame = rowFrames[item.id] else { return }
            layoutRowFrames = rowFrames
            draggingID = item.id
            dragStartCenterY = frame.midY
            dragStartWidth = frame.width
            dragTranslation = 0
            isReordering.wrappedValue = true
        }

        guard draggingID == item.id else { return }

        dragTranslation = value.translation.height
        let dragCenterY = dragStartCenterY + dragTranslation

        guard let targetIndex = PhaseReorder.targetIndex(
            dragCenterY: dragCenterY,
            draggedID: item.id,
            in: phases.wrappedValue,
            rowFrames: layoutRowFrames
        ) else { return }

        var currentPhases = phases.wrappedValue
        if PhaseReorder.moveToIndex(phases: &currentPhases, draggedID: item.id, to: targetIndex) {
            phases.wrappedValue = currentPhases
            reorderHapticTrigger.toggle()
            scheduleDragAnchorSync(for: item.id)
        }
    }

    func endDrag(isReordering: Binding<Bool>) {
        withAnimation(EditorTheme.phaseReorderAnimation) {
            draggingID = nil
            dragTranslation = 0
            dragStartCenterY = 0
            dragStartWidth = 0
            layoutRowFrames = [:]
            isReordering.wrappedValue = false
        }
    }

    private func scheduleDragAnchorSync(for id: UUID) {
        Task { @MainActor in
            syncDragAnchor(for: id)
        }
    }

    private func syncDragAnchor(for id: UUID) {
        guard let frame = rowFrames[id] else { return }
        let visualY = dragStartCenterY + dragTranslation
        dragStartCenterY = frame.midY
        dragTranslation = visualY - dragStartCenterY
        layoutRowFrames.merge(rowFrames) { _, new in new }
    }
}

struct PhaseListRow: View {
    @Binding var phase: PresetPhaseItem
    @Binding var phases: [PresetPhaseItem]
    @Bindable var session: PhaseListReorderSession
    @Binding var isReordering: Bool

    private var item: PresetPhaseItem { phase }

    private var canSwipeDelete: Bool {
        phases.count > 1 && session.draggingID == nil
    }

    var body: some View {
        PhaseCardView(
            phase: $phase,
            phaseIndex: session.phaseIndex(for: item.id, in: phases),
            phaseCount: phases.count,
            isDragging: session.draggingID == item.id,
            onDragChanged: { value in
                session.handleDragChanged(
                    for: phase,
                    value: value,
                    phases: $phases,
                    isReordering: $isReordering
                )
            },
            onDragEnded: {
                session.endDrag(isReordering: $isReordering)
            }
        )
        .allowsHitTesting(session.draggingID != item.id)
        .anchorPreference(key: PhaseRowBoundsPreference.self, value: .bounds) { anchor in
            [item.id: anchor]
        }
        .listRowInsets(EditorTheme.listRowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canSwipeDelete {
                Button(role: .destructive) {
                    deletePhase(id: item.id)
                } label: {
                    Label(String(localized: "Удалить"), systemImage: "trash")
                }
            }
        }
    }

    private func deletePhase(id: UUID) {
        guard phases.count > 1 else { return }
        withAnimation(EditorTheme.phaseReorderAnimation) {
            phases.removeAll { $0.id == id }
        }
    }
}

extension View {
    func phaseListReorderSupport(
        phases: Binding<[PresetPhaseItem]>,
        session: PhaseListReorderSession
    ) -> some View {
        modifier(PhaseListReorderSupportModifier(phases: phases, session: session))
    }
}

private struct PhaseListReorderSupportModifier: ViewModifier {
    @Binding var phases: [PresetPhaseItem]
    @Bindable var session: PhaseListReorderSession

    func body(content: Content) -> some View {
        content
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
                session.updateRowFrames(frames)
            }
            .overlayPreferenceValue(PhaseRowBoundsPreference.self) { anchors in
                dragOverlay(anchors: anchors)
            }
            .animation(
                session.draggingID == nil ? EditorTheme.phaseReorderAnimation : nil,
                value: phases.map(\.id)
            )
            .sensoryFeedback(.selection, trigger: session.reorderHapticTrigger)
    }

    @ViewBuilder
    private func dragOverlay(anchors: [UUID: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            if let draggingID = session.draggingID,
               let phase = phases.first(where: { $0.id == draggingID }) {
                let width = session.dragStartWidth > 0
                    ? session.dragStartWidth
                    : anchors[draggingID].map { proxy[$0].width } ?? proxy.size.width

                PhaseCardDragPreview(phase: phase)
                    .frame(width: width)
                    .position(
                        x: proxy.size.width / 2,
                        y: session.dragStartCenterY + session.dragTranslation
                    )
                    .allowsHitTesting(false)
                    .transition(.identity)
            }
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
    @Previewable @State var session = PhaseListReorderSession()
    List {
        Section {
            ForEach($phases) { $phase in
                PhaseListRow(
                    phase: $phase,
                    phases: $phases,
                    session: session,
                    isReordering: $isReordering
                )
            }
        } header: {
            Text(String(localized: "Круг"))
        }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .contentMargins(.horizontal, EditorTheme.horizontalPadding, for: .scrollContent)
    .phaseListReorderSupport(phases: $phases, session: session)
    .scrollDisabled(isReordering)
}
