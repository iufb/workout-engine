import SwiftUI

struct RoundCountStepper: View {
    @Binding var count: Int
    let range: ClosedRange<Int>
    var onAdjust: (() -> Void)?

    var body: some View {
        if #available(iOS 26, *) {
            glassControls
        } else {
            materialControls
        }
    }

    @available(iOS 26, *)
    private var glassControls: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                glassStepButton(
                    systemName: "minus",
                    label: String(localized: "Уменьшить"),
                    enabled: count > range.lowerBound
                ) {
                    adjust(by: -1)
                }

                glassStepButton(
                    systemName: "plus",
                    label: String(localized: "Увеличить"),
                    enabled: count < range.upperBound
                ) {
                    adjust(by: 1)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var materialControls: some View {
        HStack(spacing: 8) {
            materialStepButton(
                systemName: "minus",
                label: String(localized: "Уменьшить"),
                enabled: count > range.lowerBound
            ) {
                adjust(by: -1)
            }

            materialStepButton(
                systemName: "plus",
                label: String(localized: "Увеличить"),
                enabled: count < range.upperBound
            ) {
                adjust(by: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @available(iOS 26, *)
    private func glassStepButton(
        systemName: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .frame(width: EditorTheme.compactControlSize, height: EditorTheme.compactControlSize)
        }
        .buttonStyle(.glass)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }

    private func materialStepButton(
        systemName: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .frame(width: EditorTheme.compactControlSize, height: EditorTheme.compactControlSize)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    Circle()
                        .strokeBorder(EditorTheme.cardStroke, lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }

    private func adjust(by delta: Int) {
        let clamped = min(max(count + delta, range.lowerBound), range.upperBound)
        guard clamped != count else { return }
        count = clamped
        onAdjust?()
    }
}

#Preview {
    @Previewable @State var count = 4
    RoundCountStepper(
        count: $count,
        range: WorkoutPreset.minRoundCount ... WorkoutPreset.maxRoundCount
    )
    .padding()
}
