import SwiftUI
import UIKit

enum EditorFocusField: Hashable {
    case presetName
    case phaseDuration(UUID)
}

@MainActor
func dismissEditorKeyboard(focusedField: FocusState<EditorFocusField?>.Binding) {
    focusedField.wrappedValue = nil
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

extension View {
    /// Dismisses the keyboard when the user taps chrome inside a `List` row (`Button` — `onTapGesture` is unreliable here).
    func defocusEditorOnTap(_ focusedField: FocusState<EditorFocusField?>.Binding) -> some View {
        modifier(EditorDefocusOnTapModifier(focusedField: focusedField))
    }
}

private struct EditorDefocusOnTapModifier: ViewModifier {
    var focusedField: FocusState<EditorFocusField?>.Binding

    func body(content: Content) -> some View {
        Button {
            dismissEditorKeyboard(focusedField: focusedField)
        } label: {
            content
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
