import SwiftUI

struct WorkoutQuickStartCard: View {
    let preset: WorkoutPreset
    let showsLastUsedBadge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if showsLastUsedBadge {
                        Text(String(localized: "Последняя тренировка"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }

                    Text(preset.name)
                        .font(.title2.weight(.bold))
                }

                Spacer(minLength: 8)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            PresetSummaryCard(
                totalDuration: preset.estimatedTotalDuration,
                phases: preset.phases
            )

            Text(String(localized: "Начать"))
                .font(.headline)
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: WorkoutTheme.quickStartMinHeight, alignment: .top)
        .workoutCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String(localized: "Двойной тап для запуска тренировки"))
    }

    private var accessibilityLabel: String {
        let badge = showsLastUsedBadge ? String(localized: "Последняя тренировка, ") : ""
        return badge + preset.name + ", " + String(
            localized: "\(preset.phaseCount) фаз, \(TimeFormatting.durationLabel(preset.estimatedTotalDuration))"
        )
    }
}

#Preview {
    WorkoutQuickStartCard(preset: .tabata, showsLastUsedBadge: true)
        .padding()
}
