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
    func workoutEngine(_ engine: WorkoutEngine, countdownSecond second: Int, for phase: PhaseStep)
    func workoutEngineDidFinish(_ engine: WorkoutEngine)
    func workoutEngineDidStop(_ engine: WorkoutEngine)
}

@MainActor
@Observable
final class WorkoutEngine {
    private(set) var status: WorkoutEngineStatus = .idle
    private(set) var preset: WorkoutPreset?
    private(set) var phases: [PhaseStep] = []
    private(set) var currentPhaseIndex: Int = 0
    private(set) var phaseEndsAt: Date?
    private(set) var pausedRemaining: TimeInterval?
    private var lastCountdownSecondAnnounced: Int?

    weak var feedbackHandler: WorkoutFeedbackHandling?

    var currentPhase: PhaseStep? {
        guard phases.indices.contains(currentPhaseIndex) else { return nil }
        return phases[currentPhaseIndex]
    }

    var remaining: TimeInterval {
        remaining(at: .now)
    }

    func remaining(at date: Date) -> TimeInterval {
        switch status {
        case .running:
            guard let phaseEndsAt else { return 0 }
            return max(0, phaseEndsAt.timeIntervalSince(date))
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

    var phasePositionLabel: String? {
        guard let step = currentPhase,
              let cycleNumber = step.cyclePhaseNumber,
              let cycleTotal = step.cyclePhaseCount else { return nil }

        if let round = step.round, let totalRounds = preset?.roundCount, totalRounds > 1 {
            return L10n.t("Круг \(round) / \(totalRounds) · Фаза \(cycleNumber) / \(cycleTotal)")
        }
        return L10n.t("Фаза \(cycleNumber) / \(cycleTotal)")
    }

    var progress: Double {
        progress(at: .now)
    }

    func progress(at date: Date) -> Double {
        guard !phases.isEmpty else { return 0 }
        let completed = Double(currentPhaseIndex)
        let phaseProgress: Double
        if let step = currentPhase, step.duration > 0 {
            phaseProgress = 1 - (remaining(at: date) / step.duration)
        } else {
            phaseProgress = 0
        }
        return min(1, (completed + phaseProgress) / Double(phases.count))
    }

    /// Progress through the current phase only (0...1).
    func currentPhaseProgress(at date: Date) -> Double {
        guard let step = currentPhase, step.duration > 0 else { return 0 }
        let elapsed = step.duration - remaining(at: date)
        return min(1, max(0, elapsed / step.duration))
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
        pausedRemaining = remaining(at: .now)
        phaseEndsAt = nil
        status = .paused
        resetCountdownAnnouncement()
    }

    func resume() {
        guard status == .paused, let pausedRemaining else { return }
        status = .running
        phaseEndsAt = Date().addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
        resetCountdownAnnouncement()
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
        resetCountdownAnnouncement()
        if wasActive {
            feedbackHandler?.workoutEngineDidStop(self)
        }
    }

    /// Call on UI tick or when returning to foreground.
    func tick(now: Date = .now) {
        guard status == .running, let phaseEndsAt else { return }

        let remaining = max(0, phaseEndsAt.timeIntervalSince(now))
        announceCountdownIfNeeded(remaining: remaining)

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
        resetCountdownAnnouncement()
        phaseEndsAt = Date().addingTimeInterval(step.duration)
        if notify {
            feedbackHandler?.workoutEngine(self, didEnterPhase: step, at: currentPhaseIndex)
        }
    }

    private func announceCountdownIfNeeded(remaining: TimeInterval) {
        guard remaining > 0, let step = currentPhase else { return }
        let second = Int(ceil(remaining))
        guard (1 ... 3).contains(second) else {
            resetCountdownAnnouncement()
            return
        }
        guard lastCountdownSecondAnnounced != second else { return }
        lastCountdownSecondAnnounced = second
        feedbackHandler?.workoutEngine(self, countdownSecond: second, for: step)
    }

    private func resetCountdownAnnouncement() {
        lastCountdownSecondAnnounced = nil
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
        resetCountdownAnnouncement()
        feedbackHandler?.workoutEngineDidFinish(self)
    }
}
