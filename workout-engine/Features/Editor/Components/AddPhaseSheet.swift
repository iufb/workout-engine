import SwiftUI

struct AddPhaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (PhaseKind) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(PhaseKind.allCases, id: \.self) { kind in
                    Button {
                        onSelect(kind)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(PhaseColors.softBackground(for: kind))
                                    .frame(width: 48, height: 48)
                                Image(systemName: PhaseColors.symbolName(for: kind))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(PhaseColors.background(for: kind))
                            }

                            Text(kind.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                                .fill(.regularMaterial)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                                .strokeBorder(EditorTheme.cardStroke, lineWidth: 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Добавить фазу: \(kind.displayName)"))
                }

                Spacer()
            }
            .padding(EditorTheme.horizontalPadding)
            .navigationTitle(String(localized: "Тип фазы"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Отмена")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    AddPhaseSheet { _ in }
}
