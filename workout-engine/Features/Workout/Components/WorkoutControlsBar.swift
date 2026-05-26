import SwiftUI

struct WorkoutControlsBar: View {
    let engine: WorkoutEngine
    let phaseKind: PhaseKind?
    let onStop: () -> Void

    private var accent: PhaseKind {
        phaseKind ?? .work
    }

    var body: some View {
        VStack(spacing: 12) {
            if engine.status == .running {
                Button(String(localized: "Пауза")) {
                    engine.pause()
                }
                .buttonStyle(WorkoutPrimaryControlButtonStyle(phaseKind: accent))
                .accessibilityLabel(String(localized: "Пауза"))
            } else if engine.status == .paused {
                Button(String(localized: "Продолжить")) {
                    engine.resume()
                }
                .buttonStyle(WorkoutPrimaryControlButtonStyle(phaseKind: accent))
                .accessibilityLabel(String(localized: "Продолжить"))
            }

            HStack(spacing: 12) {
                Button(String(localized: "Пропуск")) {
                    engine.skipPhase()
                }
                .buttonStyle(WorkoutSecondaryControlButtonStyle(phaseKind: accent))
                .frame(maxWidth: .infinity)
                .accessibilityLabel(String(localized: "Пропустить фазу"))

                Button(String(localized: "Стоп")) {
                    onStop()
                }
                .buttonStyle(WorkoutSecondaryControlButtonStyle(phaseKind: accent, role: .destructive))
                .frame(maxWidth: .infinity)
                .accessibilityLabel(String(localized: "Остановить тренировку"))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 0.5)
        }
    }
}

struct WorkoutPrimaryControlButtonStyle: ButtonStyle {
    let phaseKind: PhaseKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(PhaseColors.controlFill(for: phaseKind, pressed: configuration.isPressed))
            .foregroundStyle(PhaseColors.controlLabel(on: phaseKind))
            .clipShape(Capsule())
    }
}

struct WorkoutSecondaryControlButtonStyle: ButtonStyle {
    enum Role { case normal, destructive }
    let phaseKind: PhaseKind
    var role: Role = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch role {
        case .normal:
            PhaseColors.controlLabel(on: phaseKind)
        case .destructive:
            .white
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch role {
        case .normal:
            PhaseColors.controlSecondaryFill(for: phaseKind, pressed: isPressed)
        case .destructive:
            Color.red.opacity(isPressed ? 0.75 : 0.88)
        }
    }
}

#Preview("Prepare") {
    WorkoutControlsBar(engine: WorkoutEngine(), phaseKind: .prepare, onStop: {})
        .padding()
        .background(PhaseColors.background(for: .prepare))
}

#Preview("Work") {
    WorkoutControlsBar(engine: WorkoutEngine(), phaseKind: .work, onStop: {})
        .padding()
        .background(PhaseColors.background(for: .work))
}
