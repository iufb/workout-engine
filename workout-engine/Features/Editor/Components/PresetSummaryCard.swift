import SwiftUI

struct PresetSummaryCard: View {
    let totalDuration: TimeInterval
    let phases: [PresetPhaseItem]

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
                Text(String(localized: "\(phases.count) фаз"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if !phases.isEmpty {
                phaseTimeline
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                localized: "Итого \(TimeFormatting.durationLabel(totalDuration)), \(phases.count) фаз"
            )
        )
    }

    private var phaseTimeline: some View {
        GeometryReader { geometry in
            let widths = segmentWidths(for: geometry.size.width)
            HStack(spacing: timelineSpacing) {
                ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
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
        let count = phases.count
        guard count > 0, totalWidth > 0 else { return [] }

        let gapTotal = timelineSpacing * CGFloat(max(0, count - 1))
        let available = max(0, totalWidth - gapTotal)
        let durationTotal = CGFloat(max(1, phases.reduce(0) { $0 + max(0, $1.durationSeconds) }))

        var widths = phases.map { phase in
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

#Preview("Default") {
    PresetSummaryCard(
        totalDuration: 240,
        phases: WorkoutPreset.defaultNew().phases
    )
    .editorCard()
    .padding()
}

#Preview("Tabata 16") {
    PresetSummaryCard(
        totalDuration: WorkoutPreset.tabata.estimatedTotalDuration,
        phases: WorkoutPreset.tabata.phases
    )
    .editorCard()
    .padding(.horizontal, 20)
}
