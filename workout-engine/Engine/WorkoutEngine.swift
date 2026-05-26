import Foundation
import Observation

enum WorkoutEngineStatus: Equatable, Sendable {
    case idle
    case running
    case paused
    case finished
}

protocol WorkoutFeedbackHandling: AnyObject {
    func workoutEngine(_ engine: WorkoutEngine, didEnterPhase step: PhaseStep, at index: Int)
    func workoutEngineDidFinish(_ engine: WorkoutEngine)
    func workoutEngineDidStop(_ engine: WorkoutEngine)
}

@Observable
final class WorkoutEngine {
    private(set) var status: WorkoutEngineStatus = .idle
    private(set) var preset: WorkoutPreset?
    private(set) var phases: [PhaseStep] = []
    private(set) var currentPhaseIndex: Int = 0
    private(set) var phaseEndsAt: Date?
    private(set) var pausedRemaining: TimeInterval?

    weak var feedbackHandler: WorkoutFeedbackHandling?

    var currentPhase: PhaseStep? {
        guard phases.indices.contains(currentPhaseIndex) else { return nil }
        return phases[currentPhaseIndex]
    }

    var remaining: TimeInterval {
        switch status {
        case .running:
            guard let phaseEndsAt else { return 0 }
            return max(0, phaseEndsAt.timeIntervalSinceNow)
        case .paused:
            return pausedRemaining ?? 0
        default:
            return 0
        }
    }

    var currentPhaseNumber: Int {
        guard !phases.isEmpty, phases.indices.contains(currentPhaseIndex) else { return 0 }
        return currentPhaseIndex + 1
    }

    var totalPhaseCount: Int {
        phases.count
    }

    var progress: Double {
        guard !phases.isEmpty else { return 0 }
        let completed = Double(currentPhaseIndex)
        let phaseProgress: Double
        if let step = currentPhase, step.duration > 0 {
            phaseProgress = 1 - (remaining / step.duration)
        } else {
            phaseProgress = 0
        }
        return min(1, (completed + phaseProgress) / Double(phases.count))
    }

    func load(preset: WorkoutPreset) {
        stop()
        self.preset = preset
        phases = WorkoutSequenceBuilder.sequence(for: preset)
        currentPhaseIndex = 0
    }

    func start() {
        guard !phases.isEmpty else { return }
        status = .running
        currentPhaseIndex = 0
        pausedRemaining = nil
        beginCurrentPhase(notify: false)
        feedbackHandler?.workoutEngine(self, didEnterPhase: phases[currentPhaseIndex], at: currentPhaseIndex)
    }

    func pause() {
        guard status == .running else { return }
        pausedRemaining = remaining
        phaseEndsAt = nil
        status = .paused
    }

    func resume() {
        guard status == .paused, let pausedRemaining else { return }
        status = .running
        phaseEndsAt = Date().addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
    }

    func skipPhase() {
        guard status == .running || status == .paused else { return }
        if status == .paused {
            status = .running
            pausedRemaining = nil
        }
        advancePhase()
    }

    func stop() {
        let wasActive = status != .idle && status != .finished
        status = .idle
        phaseEndsAt = nil
        pausedRemaining = nil
        currentPhaseIndex = 0
        if wasActive {
            feedbackHandler?.workoutEngineDidStop(self)
        }
    }

    /// Call on UI tick or when returning to foreground.
    func tick(now: Date = .now) {
        guard status == .running, let phaseEndsAt else { return }
        if now >= phaseEndsAt {
            advancePhase()
        }
    }

    func resync() {
        tick()
    }

    private func beginCurrentPhase(notify: Bool) {
        guard let step = currentPhase else {
            finish()
            return
        }
        phaseEndsAt = Date().addingTimeInterval(step.duration)
        if notify {
            feedbackHandler?.workoutEngine(self, didEnterPhase: step, at: currentPhaseIndex)
        }
    }

    private func advancePhase() {
        let nextIndex = currentPhaseIndex + 1
        if nextIndex >= phases.count {
            finish()
            return
        }
        currentPhaseIndex = nextIndex
        beginCurrentPhase(notify: true)
        feedbackHandler?.workoutEngine(self, didEnterPhase: phases[currentPhaseIndex], at: currentPhaseIndex)
    }

    private func finish() {
        status = .finished
        phaseEndsAt = nil
        pausedRemaining = nil
        feedbackHandler?.workoutEngineDidFinish(self)
    }
}
