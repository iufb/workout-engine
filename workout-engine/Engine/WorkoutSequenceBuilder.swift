import Foundation

enum WorkoutSequenceBuilder {
    static func sequence(for preset: WorkoutPreset) -> [PhaseStep] {
        let cycle = preset.phases
        let rounds = max(1, preset.roundCount)
        guard !cycle.isEmpty else { return [] }

        var result: [PhaseStep] = []
        result.reserveCapacity(cycle.count * rounds)

        for round in 1 ... rounds {
            for (index, phase) in cycle.enumerated() {
                let isLastRound = round == rounds
                let isLastPhase = index == cycle.count - 1
                if rounds > 1, isLastRound, isLastPhase, phase.kind == .rest {
                    continue
                }
                guard phase.durationSeconds > 0 else { continue }

                result.append(
                    PhaseStep(
                        kind: phase.kind,
                        duration: TimeInterval(phase.durationSeconds),
                        round: rounds > 1 ? round : nil,
                        cyclePhaseNumber: index + 1,
                        cyclePhaseCount: cycle.count
                    )
                )
            }
        }
        return result
    }
}
