import SwiftUI

struct PhaseCardChrome<Content: View>: View {
    let kind: PhaseKind
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                    .fill(PhaseColors.softBackground(for: kind))
            }
            .overlay {
                RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                    .strokeBorder(EditorTheme.cardStroke, lineWidth: 0.5)
            }
    }
}

struct PhaseKindIcon: View {
    let kind: PhaseKind

    var body: some View {
        ZStack {
            Circle()
                .fill(PhaseColors.softBackground(for: kind))
                .frame(width: 40, height: 40)
            Image(systemName: PhaseColors.symbolName(for: kind))
                .font(.body.weight(.semibold))
                .foregroundStyle(PhaseColors.background(for: kind))
        }
    }
}
