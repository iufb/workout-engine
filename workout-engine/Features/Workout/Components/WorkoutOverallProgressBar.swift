import SwiftUI

struct WorkoutOverallProgressBar: View {
    let progress: Double

    var body: some View {
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

#Preview {
    WorkoutOverallProgressBar(progress: 0.42)
        .padding()
        .background(Color.green)
}
