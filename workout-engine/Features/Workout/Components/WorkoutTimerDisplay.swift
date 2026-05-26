import SwiftUI

struct WorkoutTimerDisplay: View {
    let engine: WorkoutEngine

    private var isTimelinePaused: Bool {
        engine.status != .running
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: WorkoutTheme.timelineAnimationInterval, paused: isTimelinePaused)) { context in
            let date = context.date
            let remaining = engine.remaining(at: date)
            let phaseProgress = engine.currentPhaseProgress(at: date)

            ZStack {
                WorkoutPhaseProgressRing(progress: phaseProgress)
                    .frame(width: WorkoutTheme.phaseRingSize, height: WorkoutTheme.phaseRingSize)

                Text(TimeFormatting.countdown(remaining))
                    .font(.system(size: WorkoutTheme.timerFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 24)

                WorkoutEngineTick(engine: engine, date: date)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "Осталось \(TimeFormatting.countdown(remaining))"))
        }
    }
}

/// Advances phases when the timeline fires; lives inside `TimelineView` so ticks stay in sync with display.
private struct WorkoutEngineTick: View {
    let engine: WorkoutEngine
    let date: Date

    var body: some View {
        let _ = engine.tick(now: date)
        Color.clear.frame(width: 0, height: 0)
    }
}

#Preview {
    let engine = WorkoutEngine()
    engine.load(preset: WorkoutPreset.defaultNew())
    engine.start()
    return WorkoutTimerDisplay(engine: engine)
        .padding()
        .background(Color.green)
}
