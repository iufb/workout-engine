import SwiftUI

struct WorkoutOverallProgressBar: View {
    let engine: WorkoutEngine

    private var isTimelinePaused: Bool {
        engine.status != .running
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: WorkoutTheme.timelineAnimationInterval, paused: isTimelinePaused)) { context in
            let progress = engine.progress(at: context.date)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.22))
                    Capsule()
                        .fill(.white.opacity(0.92))
                        .frame(width: max(0, geometry.size.width * min(1, max(0, progress))))
                        .animation(WorkoutTheme.progressAnimation, value: progress)
                }
            }
            .frame(height: 5)
            .accessibilityLabel(L10n.t("Прогресс тренировки"))
            .accessibilityValue(Text(L10n.t("\(Int(progress * 100))%")))
        }
    }
}

#Preview {
    let engine = WorkoutEngine()
    engine.load(preset: .tabata)
    engine.start()
    return WorkoutOverallProgressBar(engine: engine)
        .padding()
        .background(Color.green)
}
