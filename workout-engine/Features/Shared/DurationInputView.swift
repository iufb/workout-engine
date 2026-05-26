import SwiftUI

struct DurationInputView: View {
    let kind: PhaseKind
    @Binding var seconds: Int
    var editorFocus: FocusState<EditorFocusField?>.Binding
    let editorFocusCase: EditorFocusField
    @State private var text: String = ""
    @State private var hasParseError = false

    private var isFieldFocused: Bool {
        editorFocus.wrappedValue == editorFocusCase
    }

    var body: some View {
        HStack(spacing: 10) {
            stepperButton(systemName: "minus", label: L10n.t("Уменьшить")) {
                adjust(by: -step)
            }

            TextField("0", text: $text)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 64)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: EditorTheme.pillRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: EditorTheme.pillRadius, style: .continuous)
                        .strokeBorder(hasParseError ? Color.red : EditorTheme.cardStroke, lineWidth: hasParseError ? 1.5 : 0.5)
                }
                .focused(editorFocus, equals: editorFocusCase)
                .foregroundStyle(hasParseError ? .red : .primary)
                .onSubmit { commitText() }
                .onChange(of: editorFocus.wrappedValue) { _, newValue in
                    if newValue != editorFocusCase { commitText() }
                }
                .accessibilityLabel(L10n.t("Длительность"))

            stepperButton(systemName: "plus", label: L10n.t("Увеличить")) {
                adjust(by: step)
            }
        }
        .onAppear { syncTextFromSeconds() }
        .onChange(of: seconds) { _, _ in
            if !isFieldFocused { syncTextFromSeconds() }
        }
    }

    private func stepperButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            dismissEditorKeyboard(focusedField: editorFocus)
            action()
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: EditorTheme.controlSize, height: EditorTheme.controlSize)
                .background {
                    Circle()
                        .fill(PhaseColors.softBackground(for: kind))
                }
                .foregroundStyle(PhaseColors.background(for: kind))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var step: Int {
        DurationParsing.step(for: seconds)
    }

    private var allowedRange: ClosedRange<Int> {
        DurationParsing.allowedRange(for: kind)
    }

    private func adjust(by delta: Int) {
        hasParseError = false
        seconds = min(max(seconds + delta, allowedRange.lowerBound), allowedRange.upperBound)
        syncTextFromSeconds()
    }

    private func commitText() {
        switch DurationParsing.parse(text, kind: kind) {
        case .success(let value):
            hasParseError = false
            seconds = value
            text = DurationParsing.format(seconds: value)
        case .failure:
            hasParseError = true
        }
    }

    private func syncTextFromSeconds() {
        text = DurationParsing.format(seconds: seconds)
        hasParseError = false
    }
}

#Preview {
    @Previewable @State var seconds = 90
    @Previewable @FocusState var focus: EditorFocusField?
    let previewID = UUID()
    DurationInputView(
        kind: .work,
        seconds: $seconds,
        editorFocus: $focus,
        editorFocusCase: .phaseDuration(previewID)
    )
    .padding()
}
