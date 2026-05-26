import SwiftUI

struct PresetSummaryCard: View {
    let totalDuration: TimeInterval
    let cyclePhases: [PresetPhaseItem]
    let roundCount: Int

    private let timelineSpacing: CGFloat = 2
    private let timelineHeight: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(TimeFormatting.durationLabel(totalDuration))
                    .font(.title.weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Spacer()
                Text(metaLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            if !cyclePhases.isEmpty {
                phaseTimeline
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var metaLabel: String {
        let phasePart = L10n.t("\(cyclePhases.count) фаз")
        guard roundCount > 1 else { return phasePart }
        return phasePart + L10n.t(" · ") + RoundsFormatting.label(count: roundCount)
    }

    private var accessibilityLabel: String {
        let duration = TimeFormatting.durationLabel(totalDuration)
        if roundCount > 1 {
            return L10n.t("Итого \(duration), \(cyclePhases.count) фаз в круге, \(roundCount) кругов")
        }
        return L10n.t("Итого \(duration), \(cyclePhases.count) фаз")
    }

    private var phaseTimeline: some View {
        GeometryReader { geometry in
            let widths = segmentWidths(for: geometry.size.width)
            HStack(spacing: timelineSpacing) {
                ForEach(Array(cyclePhases.enumerated()), id: \.element.id) { index, phase in
                    Capsule()
                        .fill(PhaseColors.background(for: phase.kind))
                        .frame(width: widths[index])
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(height: timelineHeight)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    /// Distributes width across segments so total including gaps never exceeds `totalWidth`.
    private func segmentWidths(for totalWidth: CGFloat) -> [CGFloat] {
        let count = cyclePhases.count
        guard count > 0, totalWidth > 0 else { return [] }

        let gapTotal = timelineSpacing * CGFloat(max(0, count - 1))
        let available = max(0, totalWidth - gapTotal)
        let durationTotal = CGFloat(max(1, cyclePhases.reduce(0) { $0 + max(0, $1.durationSeconds) }))

        var widths = cyclePhases.map { phase in
            available * CGFloat(max(0, phase.durationSeconds)) / durationTotal
        }

        let sum = widths.reduce(0, +)
        if sum > available, sum > 0 {
            let scale = available / sum
            widths = widths.map { $0 * scale }
        }

        return widths
    }
}

enum RoundsFormatting {
    static func label(count: Int) -> String {
        L10n.t("\(count) кругов")
    }
}

#Preview("Default") {
    PresetSummaryCard(
        totalDuration: 40,
        cyclePhases: WorkoutPreset.defaultNew().phases,
        roundCount: 1
    )
    .editorCard()
    .padding()
}

#Preview("Tabata") {
    PresetSummaryCard(
        totalDuration: WorkoutPreset.tabata.estimatedTotalDuration,
        cyclePhases: WorkoutPreset.tabata.phases,
        roundCount: WorkoutPreset.tabata.roundCount
    )
    .editorCard()
    .padding(.horizontal, 20)
}
