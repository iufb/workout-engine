import SwiftUI

struct WorkoutPhaseHeader: View {
    let presetName: String
    let phaseKind: PhaseKind?
    let currentPhaseNumber: Int
    let totalPhaseCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Text(presetName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
                .textCase(.uppercase)
                .tracking(0.6)

            if let phaseKind {
                WorkoutPhaseHeaderIcon(kind: phaseKind)

                Text(phaseKind.displayName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
            }

            if totalPhaseCount > 0 {
                Text(String(localized: "Фаза \(currentPhaseNumber) / \(totalPhaseCount)"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .multilineTextAlignment(.center)
    }
}

struct WorkoutPhaseHeaderIcon: View {
    let kind: PhaseKind

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 56, height: 56)
            Image(systemName: PhaseColors.symbolName(for: kind))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    WorkoutPhaseHeader(
        presetName: "Tabata",
        phaseKind: .work,
        currentPhaseNumber: 3,
        totalPhaseCount: 16
    )
    .padding()
    .background(Color.green)
}
