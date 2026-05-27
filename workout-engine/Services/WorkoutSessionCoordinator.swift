import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class WorkoutSessionCoordinator: WorkoutFeedbackHandling {
    let engine = WorkoutEngine()
    private var tickTask: Task<Void, Never>?
    private var isWorkoutSessionActive = false

    init() {
        engine.feedbackHandler = self
        AudioSessionManager.shared.onInterruptionEnded = { [weak self] in
            self?.restoreSessionAudioIfNeeded()
        }
    }

    func start(preset: WorkoutPreset) {
        AppSettings.shared.lastUsedPresetID = preset.id
        isWorkoutSessionActive = true
        do {
            try AudioSessionManager.shared.activateForWorkout()
            SoundPlayer.shared.prepareForWorkoutSession()
        } catch {
            // Continue without background audio if session fails.
        }
        SoundPlayer.shared.startSessionAudio()
        updateIdleTimer(disabled: AppSettings.shared.keepScreenOnDuringWorkout)
        engine.load(preset: preset)
        engine.start()
        startTickLoop()
    }

    func stop() {
        stopTickLoop()
        engine.stop()
    }

    func syncSession(now: Date = .now) {
        engine.syncToWallClock(now: now)
    }

    // MARK: - WorkoutFeedbackHandling

    nonisolated func workoutEngine(_ engine: WorkoutEngine, didEnterPhase step: PhaseStep, at index: Int) {
        Task { @MainActor in
            guard engine.status == .running else { return }
            // Keep a single cue on phase boundaries: "ring" is played on `didCompletePhase`.
            // Still play a start cue for the very first phase so session start feels responsive.
            if index == 0 {
                SoundPlayer.shared.playPhaseStartLoud(for: step.kind)
            }
            HapticService.shared.phaseTransition(for: step.kind)
        }
    }

    nonisolated func workoutEngine(_ engine: WorkoutEngine, didCompletePhase step: PhaseStep, at index: Int) {
        Task { @MainActor in
            guard engine.status == .running else { return }
            SoundPlayer.shared.playPhaseEndRing(for: step.kind)
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
        isWorkoutSessionActive = false
        stopTickLoop()
        SoundPlayer.shared.stopSessionAudio()
        AudioSessionManager.shared.deactivate()
        updateIdleTimer(disabled: false)
    }

    private func restoreSessionAudioIfNeeded() {
        guard isWorkoutSessionActive else { return }
        guard engine.status == .running || engine.status == .paused else { return }
        SoundPlayer.shared.prepareForWorkoutSession()
        SoundPlayer.shared.startSessionAudio()
    }

    private func startTickLoop() {
        stopTickLoop()
        let interval = WorkoutTheme.timelineTickInterval
        tickTask = Task { @MainActor in
            while !Task.isCancelled {
                if engine.status == .running {
                    engine.tick(now: .now)
                }
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func stopTickLoop() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func updateIdleTimer(disabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disabled
    }
}
