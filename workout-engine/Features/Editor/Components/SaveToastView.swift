import SwiftUI

struct SaveToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                Capsule(style: .continuous)
                    .fill(.regularMaterial)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(EditorTheme.cardStroke, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .padding(.horizontal, EditorTheme.horizontalPadding)
    }
}

#Preview {
    SaveToastView(message: L10n.t("Интервал сохранён"))
}
