import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class WorkoutSessionCoordinator: WorkoutFeedbackHandling {
    let engine = WorkoutEngine()

    init() {
        engine.feedbackHandler = self
    }

    func start(preset: WorkoutPreset) {
        AppSettings.shared.lastUsedPresetID = preset.id
        do {
            try AudioSessionManager.shared.activateForWorkout()
        } catch {
            // Continue without background audio if session fails.
        }
        SoundPlayer.shared.startKeepAlive()
        updateIdleTimer(disabled: AppSettings.shared.keepScreenOnDuringWorkout)
        engine.load(preset: preset)
        engine.start()
    }

    func stop() {
        engine.stop()
    }

    // MARK: - WorkoutFeedbackHandling

    nonisolated func workoutEngine(_ engine: WorkoutEngine, didEnterPhase step: PhaseStep, at index: Int) {
        Task { @MainActor in
            guard engine.status == .running else { return }
            SoundPlayer.shared.playPhaseStartLoud(for: step.kind)
            HapticService.shared.phaseTransition(for: step.kind)
        }
    }

    nonisolated func workoutEngine(_ engine: WorkoutEngine, countdownSecond second: Int, for phase: PhaseStep) {
        Task { @MainActor in
            guard engine.status == .running else { return }
            SoundPlayer.shared.playCountdownSoft(for: phase.kind)
            HapticService.shared.countdownTick()
        }
    }

    nonisolated func workoutEngineDidFinish(_ engine: WorkoutEngine) {
        Task { @MainActor in
            SoundPlayer.shared.playWorkoutComplete()
            HapticService.shared.workoutFinished()
            teardownSession()
        }
    }

    nonisolated func workoutEngineDidStop(_ engine: WorkoutEngine) {
        Task { @MainActor in
            HapticService.shared.workoutStopped()
            teardownSession()
        }
    }

    private func teardownSession() {
        SoundPlayer.shared.stopKeepAlive()
        AudioSessionManager.shared.deactivate()
        updateIdleTimer(disabled: false)
    }

    private func updateIdleTimer(disabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disabled
    }
}
