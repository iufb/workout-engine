import Foundation

enum PresetMigration {
    /// Converts legacy prepare + rounds × (work, rest) into a linear phase list.
    static func phasesFromLegacy(
        rounds: Int,
        prepareSeconds: Double,
        workSeconds: Double,
        restSeconds: Double
    ) -> [PresetPhaseItem] {
        var phases: [PresetPhaseItem] = []
        if prepareSeconds >= 1 {
            phases.append(PresetPhaseItem(kind: .prepare, durationSeconds: Int(prepareSeconds)))
        }
        let roundCount = max(1, rounds)
        for round in 1 ... roundCount {
            phases.append(PresetPhaseItem(kind: .work, durationSeconds: max(1, Int(workSeconds))))
            if round < roundCount, restSeconds > 0 {
                phases.append(PresetPhaseItem(kind: .rest, durationSeconds: max(1, Int(restSeconds))))
            }
        }
        return phases
    }

    static func decodePhases(from json: String) -> [PresetPhaseItem]? {
        guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([PresetPhaseItem].self, from: data)
    }

    static func encodePhases(_ phases: [PresetPhaseItem]) -> String {
        guard let data = try? JSONEncoder().encode(phases),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
