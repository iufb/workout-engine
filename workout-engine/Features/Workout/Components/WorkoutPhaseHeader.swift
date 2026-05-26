import SwiftUI

struct WorkoutPhaseHeader: View {
    let presetName: String
    let phaseKind: PhaseKind?
    let positionLabel: String?
    let remaining: TimeInterval

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

            if let positionLabel {
                Text(positionLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts = [presetName]
        if let phaseKind {
            parts.append(phaseKind.displayName)
        }
        if let positionLabel {
            parts.append(positionLabel)
        }
        parts.append(L10n.t("Осталось \(TimeFormatting.countdown(remaining))"))
        return parts.joined(separator: ", ")
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
        positionLabel: L10n.t("Круг 2 / 5 · Фаза 3 / 4"),
        remaining: 18
    )
    .padding()
    .background(Color.green)
}
