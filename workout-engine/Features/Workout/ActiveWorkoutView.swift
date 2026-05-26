import SwiftUI

struct ActiveWorkoutView: View {
    @Bindable var coordinator: WorkoutSessionCoordinator
    let preset: WorkoutPreset
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showStopConfirmation = false

    private var engine: WorkoutEngine { coordinator.engine }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: engine.currentPhase?.kind)

            VStack(spacing: 24) {
                header
                Spacer()
                timerDisplay
                Spacer()
                controls
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: "Закрыть")) {
                    showStopConfirmation = true
                }
                .foregroundStyle(.white)
            }
        }
        .confirmationDialog(
            String(localized: "Остановить тренировку?"),
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Остановить"), role: .destructive) {
                coordinator.stop()
                dismiss()
            }
            Button(String(localized: "Продолжить"), role: .cancel) {}
        }
        .onAppear {
            coordinator.start(preset: preset)
        }
        .onDisappear {
            if engine.status == .running || engine.status == .paused {
                coordinator.stop()
            }
        }
        .overlay {
            WorkoutTickDriver(engine: engine)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                engine.resync()
            }
        }
        .onChange(of: engine.status) { _, status in
            if status == .finished {
                dismiss()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var backgroundColor: Color {
        if let kind = engine.currentPhase?.kind {
            return PhaseColors.background(for: kind)
        }
        return Color.black
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(preset.name)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            if engine.totalPhaseCount > 0 {
                Text(String(localized: "Фаза \(engine.currentPhaseNumber) / \(engine.totalPhaseCount)"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            if let phase = engine.currentPhase {
                Text(phase.kind.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .accessibilityLabel(phase.kind.displayName)
            }
        }
    }

    private var timerDisplay: some View {
        Text(TimeFormatting.countdown(engine.remaining))
            .font(.system(size: 96, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .accessibilityLabel(String(localized: "Осталось \(TimeFormatting.countdown(engine.remaining))"))
    }

    private var controls: some View {
        HStack(spacing: 16) {
            if engine.status == .running {
                Button(String(localized: "Пауза")) {
                    engine.pause()
                }
                .buttonStyle(WorkoutControlButtonStyle())
            } else if engine.status == .paused {
                Button(String(localized: "Продолжить")) {
                    engine.resume()
                }
                .buttonStyle(WorkoutControlButtonStyle())
            }

            Button(String(localized: "Пропуск")) {
                engine.skipPhase()
            }
            .buttonStyle(WorkoutControlButtonStyle())

            Button(String(localized: "Стоп")) {
                showStopConfirmation = true
            }
            .buttonStyle(WorkoutControlButtonStyle(role: .destructive))
        }
    }
}

private struct WorkoutControlButtonStyle: ButtonStyle {
    enum Role { case normal, destructive }
    var role: Role = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(role == .destructive ? Color.red.opacity(0.85) : Color.white.opacity(0.22))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Drives `engine.tick()` on a periodic timeline (UI refresh only; timing uses `phaseEndsAt`).
private struct WorkoutTickDriver: View {
    let engine: WorkoutEngine

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            TickSideEffect(action: { engine.tick() })
        }
        .allowsHitTesting(false)
    }
}

private struct TickSideEffect: View {
    let action: () -> Void

    var body: some View {
        let _ = action()
        Color.clear.frame(width: 0, height: 0)
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(
            coordinator: WorkoutSessionCoordinator(),
            preset: .tabata
        )
    }
}
