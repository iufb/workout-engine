import SwiftUI

/// Lightweight preset summary for list rows (no phase timeline).
struct WorkoutPresetListSummary: View {
    let totalDuration: TimeInterval
    let cyclePhaseCount: Int
    let roundCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(TimeFormatting.durationLabel(totalDuration))
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(metaLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var metaLabel: String {
        let phasePart = L10n.t("\(cyclePhaseCount) фаз")
        guard roundCount > 1 else { return phasePart }
        return phasePart + L10n.t(" · ") + RoundsFormatting.label(count: roundCount)
    }

    private var accessibilityLabel: String {
        let duration = TimeFormatting.durationLabel(totalDuration)
        if roundCount > 1 {
            return L10n.t("\(duration), \(cyclePhaseCount) фаз в круге, \(roundCount) кругов")
        }
        return L10n.t("\(duration), \(cyclePhaseCount) фаз")
    }
}

#Preview {
    WorkoutPresetListSummary(
        totalDuration: 120,
        cyclePhaseCount: 3,
        roundCount: 4
    )
    .padding()
}
