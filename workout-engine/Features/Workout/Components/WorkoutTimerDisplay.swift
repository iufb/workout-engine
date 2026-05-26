import SwiftUI

struct WorkoutTimerDisplay: View {
    let remaining: TimeInterval
    let phaseProgress: Double
    let ringSize: CGFloat
    let timerFontSize: CGFloat

    var body: some View {
        ZStack {
            WorkoutPhaseProgressRing(progress: phaseProgress)
                .frame(width: ringSize, height: ringSize)

            Text(TimeFormatting.countdown(remaining))
                .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.t("Осталось \(TimeFormatting.countdown(remaining))"))
    }
}

#Preview {
    WorkoutTimerDisplay(
        remaining: 42,
        phaseProgress: 0.65,
        ringSize: WorkoutTheme.phaseRingSize,
        timerFontSize: WorkoutTheme.timerFontSize
    )
    .padding()
    .background(Color.green)
}
