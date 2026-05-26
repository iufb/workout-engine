import Foundation

enum PresetCycleExpander {
    static func expand(cycle: [PresetPhaseItem], roundCount: Int) -> [PresetPhaseItem] {
        let rounds = max(1, roundCount)
        guard !cycle.isEmpty else { return [] }

        var result: [PresetPhaseItem] = []
        result.reserveCapacity(cycle.count * rounds)

        for round in 1 ... rounds {
            for (index, phase) in cycle.enumerated() {
                let isLastRound = round == rounds
                let isLastPhase = index == cycle.count - 1
                if rounds > 1, isLastRound, isLastPhase, phase.kind == .rest {
                    continue
                }
                result.append(
                    PresetPhaseItem(
                        id: UUID(),
                        kind: phase.kind,
                        durationSeconds: phase.durationSeconds
                    )
                )
            }
        }
        return result
    }
}
