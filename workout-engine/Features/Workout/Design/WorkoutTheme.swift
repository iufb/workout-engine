import SwiftUI

enum WorkoutTheme {
    static let cardRadius = EditorTheme.cardRadius
    static let horizontalPadding = EditorTheme.horizontalPadding
    static let sectionSpacing = EditorTheme.sectionSpacing
    static let quickStartMinHeight: CGFloat = 160
    static let finishOverlayDuration: Duration = .seconds(2.0)
    static let confettiPieceCount = 80
    static let confettiAnimationInterval: TimeInterval = 1.0 / 30.0

    static let timerFontSize: CGFloat = 96
    static let phaseRingSize: CGFloat = 260
    static let phaseRingLineWidth: CGFloat = 10
    static let controlsBottomPadding: CGFloat = 8
    static let timelineTickInterval: TimeInterval = 0.25
    static let timelineAnimationInterval: TimeInterval = 1.0 / 30.0

    static var phaseTransitionAnimation: Animation {
        .easeInOut(duration: 0.35)
    }

    static var progressAnimation: Animation {
        .linear(duration: timelineAnimationInterval)
    }

    static var groupedBackground: Color {
        EditorTheme.groupedBackground
    }

    static var cardStroke: Color {
        EditorTheme.cardStroke
    }
}

struct WorkoutCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(WorkoutTheme.horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: WorkoutTheme.cardRadius, style: .continuous)
                    .fill(.regularMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: WorkoutTheme.cardRadius, style: .continuous)
                    .strokeBorder(WorkoutTheme.cardStroke, lineWidth: 0.5)
            }
    }
}

extension View {
    func workoutCard() -> some View {
        modifier(WorkoutCardModifier())
    }
}
