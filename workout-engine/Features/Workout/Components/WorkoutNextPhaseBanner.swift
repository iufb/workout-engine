import SwiftUI

struct WorkoutNextPhaseBanner: View {
    let nextPhase: PhaseStep

    var body: some View {
        Text(
            String(
                localized: "Далее: \(nextPhase.kind.displayName) · \(TimeFormatting.durationLabel(nextPhase.duration))"
            )
        )
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.18), in: Capsule())
        .accessibilityLabel(
            String(
                localized: "Следующая фаза \(nextPhase.kind.displayName), \(TimeFormatting.durationLabel(nextPhase.duration))"
            )
        )
    }
}

#Preview {
    WorkoutNextPhaseBanner(
        nextPhase: PhaseStep(kind: .rest, duration: 10)
    )
    .padding()
    .background(Color.blue)
}
