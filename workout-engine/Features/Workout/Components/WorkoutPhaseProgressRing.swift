import SwiftUI

struct WorkoutPhaseProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat

    init(progress: Double, lineWidth: CGFloat = WorkoutTheme.phaseRingLineWidth) {
        self.progress = progress
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.22), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(
                    .white.opacity(0.95),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(WorkoutTheme.progressAnimation, value: progress)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.t("Прогресс текущей фазы"))
        .accessibilityValue(Text(L10n.t("\(Int(progress * 100))%")))
    }
}

#Preview {
    WorkoutPhaseProgressRing(progress: 0.65)
        .frame(width: 200, height: 200)
        .padding()
        .background(Color.green)
}
