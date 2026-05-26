import SwiftUI

struct ActiveWorkoutView: View {
    @Bindable var coordinator: WorkoutSessionCoordinator
    @Bindable private var engine: WorkoutEngine
    let preset: WorkoutPreset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize = WorkoutTheme.timerFontSize
    @ScaledMetric(relativeTo: .largeTitle) private var phaseRingSize = WorkoutTheme.phaseRingSize
    @State private var showStopConfirmation = false
    @State private var showFinishOverlay = false
    @State private var sessionEnded = false

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

    private var isTimelinePaused: Bool {
        engine.status != .running
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: WorkoutTheme.timelineAnimationInterval, paused: isTimelinePaused)) { context in
            let date = context.date
            let remaining = engine.remaining(at: date)
            let phaseProgress = engine.currentPhaseProgress(at: date)
            let overallProgress = engine.progress(at: date)

            ZStack {
                backgroundLayer
                    .animation(WorkoutTheme.phaseTransitionAnimation, value: engine.currentPhaseIndex)

                VStack(spacing: 0) {
                    WorkoutOverallProgressBar(progress: overallProgress)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    WorkoutPhaseHeader(
                        presetName: preset.name,
                        phaseKind: engine.currentPhase?.kind,
                        positionLabel: engine.phasePositionLabel,
                        remaining: remaining
                    )
                    .animation(WorkoutTheme.phaseTransitionAnimation, value: engine.currentPhaseIndex)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 16)

                    WorkoutTimerDisplay(
                        remaining: remaining,
                        phaseProgress: phaseProgress,
                        ringSize: phaseRingSize,
                        timerFontSize: timerFontSize
                    )

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
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.t("Прервать")) {
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
                endSessionAndDismiss()
            }
            Button(L10n.t("Продолжить"), role: .cancel) {}
        }
        .onAppear {
            sessionEnded = false
            coordinator.start(preset: preset)
        }
        .onDisappear {
            guard !sessionEnded else { return }
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

    private func endSessionAndDismiss() {
        sessionEnded = true
        coordinator.stop()
        dismiss()
    }

    private func presentFinishAndDismiss() {
        sessionEnded = true
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
