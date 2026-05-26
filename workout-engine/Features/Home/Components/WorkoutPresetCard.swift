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
                    phases: preset.phases
                )
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .workoutCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                localized: "\(preset.name), \(preset.phaseCount) фаз, \(TimeFormatting.durationLabel(preset.estimatedTotalDuration))"
            )
        )
    }
}

#Preview {
    WorkoutPresetCard(preset: WorkoutPreset.defaultNew())
        .padding()
}
