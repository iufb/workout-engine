import SwiftUI

enum EditorTheme {
    static let cardRadius: CGFloat = 16
    static let pillRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 12
    static let phaseCardMinHeight: CGFloat = 88
    static let controlSize: CGFloat = 44
    static let scrollBottomPadding: CGFloat = 16
    static let phaseReorderCoordinateSpace = "PhaseReorderList"
    static let phaseReorderAnimation: Animation = .smooth(duration: 0.28)

    static var groupedBackground: Color {
        Color(.systemGroupedBackground)
    }

    static var cardStroke: Color {
        Color.primary.opacity(0.08)
    }
}

struct EditorCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EditorTheme.horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                    .fill(.regularMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous)
                    .strokeBorder(EditorTheme.cardStroke, lineWidth: 0.5)
            }
    }
}

extension View {
    func editorCard() -> some View {
        modifier(EditorCardModifier())
    }
}
