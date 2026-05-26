import SwiftUI

struct PhaseCardView: View {
    @Binding var phase: PresetPhaseItem
    let phaseIndex: Int
    let phaseCount: Int
    let isDragging: Bool
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: () -> Void

    init(
        phase: Binding<PresetPhaseItem>,
        phaseIndex: Int,
        phaseCount: Int,
        isDragging: Bool = false,
        onDragChanged: @escaping (DragGesture.Value) -> Void = { _ in },
        onDragEnded: @escaping () -> Void = {}
    ) {
        _phase = phase
        self.phaseIndex = phaseIndex
        self.phaseCount = phaseCount
        self.isDragging = isDragging
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    var body: some View {
        PhaseCardChrome(kind: phase.kind) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .gesture(reorderGesture)
                    .accessibilityLabel(String(localized: "Переместить"))

                PhaseKindIcon(kind: phase.kind)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {
                    Text(phase.kind.displayName)
                        .font(.headline)

                    DurationInputView(kind: phase.kind, seconds: $phase.durationSeconds)
                }
            }
            .frame(minHeight: EditorTheme.phaseCardMinHeight - 28, alignment: .center)
        }
        .opacity(isDragging ? 0 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(String(localized: "Свайп влево для удаления. Перетащите за ручку слева для смены порядка."))
    }

    private var reorderGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(EditorTheme.phaseReorderCoordinateSpace))
            .onChanged(onDragChanged)
            .onEnded { _ in onDragEnded() }
    }

    private var accessibilitySummary: String {
        String(
            localized: "\(phase.kind.displayName), \(phase.durationSeconds) секунд, фаза \(phaseIndex) из \(phaseCount)"
        )
    }
}

#Preview {
    @Previewable @State var phase = PresetPhaseItem(kind: .work, durationSeconds: 45)
    PhaseCardView(phase: $phase, phaseIndex: 1, phaseCount: 3)
        .padding()
}
