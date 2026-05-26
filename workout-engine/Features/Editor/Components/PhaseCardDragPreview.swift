import SwiftUI

/// Lifted preview during drag — colored card only, no controls or list chrome.
struct PhaseCardDragPreview: View {
    let phase: PresetPhaseItem

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
    }

    var body: some View {
        PhaseCardChrome(kind: phase.kind) {
            HStack(spacing: 12) {
                PhaseKindIcon(kind: phase.kind)

                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.kind.displayName)
                        .font(.headline)
                    Text(DurationParsing.format(seconds: phase.durationSeconds))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
        }
        .frame(minHeight: 72)
        .clipShape(cardShape)
        .compositingGroup()
        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
        .scaleEffect(1.02)
    }
}

#Preview {
    PhaseCardDragPreview(phase: PresetPhaseItem(kind: .work, durationSeconds: 90))
        .padding()
}
