import SwiftUI

struct WorkoutQuickStartCard: View {
    let preset: WorkoutPreset
    let showsLastUsedBadge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if showsLastUsedBadge {
                        Text(L10n.t("Последняя тренировка"))
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
                cyclePhases: preset.phases,
                roundCount: preset.roundCount
            )

            Text(L10n.t("Начать"))
                .font(.headline)
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: WorkoutTheme.quickStartMinHeight, alignment: .top)
        .workoutCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(L10n.t("Двойной тап для запуска тренировки"))
    }

    private var accessibilityLabel: String {
        let badge = showsLastUsedBadge ? L10n.t("Последняя тренировка, ") : ""
        return badge + preset.name + ", " + L10n.t("\(preset.phaseCount) фаз, \(TimeFormatting.durationLabel(preset.estimatedTotalDuration))")
    }
}

#Preview {
    WorkoutQuickStartCard(preset: .defaultNew(), showsLastUsedBadge: true)
        .padding()
}
