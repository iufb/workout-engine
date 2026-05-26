import SwiftUI

struct EditorSaveBar: View {
    let canSave: Bool
    let validationHint: String?
    let showsTabataReset: Bool
    let onSave: () -> Void
    let onResetTabata: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if let validationHint {
                Text(validationHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showsTabataReset {
                Button(String(localized: "Сбросить Tabata к стандарту"), action: onResetTabata)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onSave) {
                Text(String(localized: "Сохранить"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.55)
        }
        .padding(.horizontal, EditorTheme.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    EditorSaveBar(
        canSave: false,
        validationHint: String(localized: "Введите название"),
        showsTabataReset: true,
        onSave: {},
        onResetTabata: {}
    )
}
