import SwiftUI

struct ActiveWorkoutView: View {
    @Bindable var coordinator: WorkoutSessionCoordinator
    @Bindable private var engine: WorkoutEngine
    let preset: WorkoutPreset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showStopConfirmation = false
    @State private var showFinishOverlay = false

    init(coordinator: WorkoutSessionCoordinator, preset: WorkoutPreset) {
        self.coordinator = coordinator
        self._engine = Bindable(wrappedValue: coordinator.engine)
        self.preset = preset
    }

    private var nextPhase: PhaseStep? {
        let nextIndex = engine.currentPhaseIndex + 1
        guard engine.phases.indices.contains(nextIndex) else { return nil }
        return engine.phases[nextIndex]
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                WorkoutOverallProgressBar(engine: engine)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                WorkoutPhaseHeader(
                    presetName: preset.name,
                    phaseKind: engine.currentPhase?.kind,
                    currentPhaseNumber: engine.currentPhaseNumber,
                    totalPhaseCount: engine.totalPhaseCount
                )
                .padding(.top, 16)
                .padding(.horizontal, 20)

                Spacer(minLength: 16)

                WorkoutTimerDisplay(engine: engine)

                Spacer(minLength: 12)

                if let nextPhase, engine.status == .running || engine.status == .paused {
                    WorkoutNextPhaseBanner(nextPhase: nextPhase)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 16)

                WorkoutControlsBar(
                    engine: engine,
                    phaseKind: engine.currentPhase?.kind
                ) {
                    showStopConfirmation = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, WorkoutTheme.controlsBottomPadding)
            }

            if showFinishOverlay {
                WorkoutFinishOverlay()
            }
        }
        .animation(WorkoutTheme.phaseTransitionAnimation, value: engine.currentPhaseIndex)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.t("Закрыть")) {
                    showStopConfirmation = true
                }
                .foregroundStyle(toolbarForeground)
                .fontWeight(.semibold)
            }
        }
        .confirmationDialog(
            L10n.t("Остановить тренировку?"),
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.t("Остановить"), role: .destructive) {
                coordinator.stop()
                dismiss()
            }
            Button(L10n.t("Продолжить"), role: .cancel) {}
        }
        .onAppear {
            coordinator.start(preset: preset)
        }
        .onDisappear {
            if engine.status == .running || engine.status == .paused {
                coordinator.stop()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                engine.resync()
            }
        }
        .onChange(of: engine.status) { _, status in
            if status == .finished {
                presentFinishAndDismiss()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var toolbarForeground: Color {
        if let kind = engine.currentPhase?.kind {
            return PhaseColors.onPhaseBackground(for: kind)
        }
        return .white
    }

    private var backgroundLayer: some View {
        ZStack {
            if let kind = engine.currentPhase?.kind {
                PhaseColors.background(for: kind)
            } else {
                Color.black
            }

            LinearGradient(
                colors: [.white.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }

    private func presentFinishAndDismiss() {
        withAnimation(.smooth) {
            showFinishOverlay = true
        }
        Task {
            try? await Task.sleep(for: WorkoutTheme.finishOverlayDuration)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView(
            coordinator: WorkoutSessionCoordinator(),
            preset: .defaultNew()
        )
    }
}
