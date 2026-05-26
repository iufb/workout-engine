import SwiftUI

struct WorkoutPresetCard: View {
    let preset: WorkoutPreset

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(preset.name)
                    .font(.headline)

                PresetSummaryCard(
                    totalDuration: preset.estimatedTotalDuration,
                    cyclePhases: preset.phases,
                    roundCount: preset.roundCount
                )
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .workoutCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let duration = TimeFormatting.durationLabel(preset.estimatedTotalDuration)
        if preset.roundCount > 1 {
            return String(
                localized: "\(preset.name), \(preset.phaseCount) фаз, \(preset.roundCount) кругов, \(duration)"
            )
        }
        return String(
            localized: "\(preset.name), \(preset.phaseCount) фаз, \(duration)"
        )
    }
}

#Preview {
    WorkoutPresetCard(preset: WorkoutPreset.defaultNew())
        .padding()
}
