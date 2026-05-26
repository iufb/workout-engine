import Foundation

enum PresetMigration {
    private struct PresetPhasesPayloadV2: Codable {
        let version: Int
        let cycle: [PresetPhaseItem]
        let roundCount: Int
    }

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

    struct PresetPhaseDefinition {
        let cycle: [PresetPhaseItem]
        let roundCount: Int
    }

    static func decodePresetDefinition(from json: String) -> PresetPhaseDefinition? {
        guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }

        if let v2 = try? JSONDecoder().decode(PresetPhasesPayloadV2.self, from: data), v2.version == 2 {
            guard !v2.cycle.isEmpty else { return nil }
            return PresetPhaseDefinition(
                cycle: v2.cycle,
                roundCount: max(WorkoutPreset.minRoundCount, v2.roundCount)
            )
        }

        if let cycle = try? JSONDecoder().decode([PresetPhaseItem].self, from: data), !cycle.isEmpty {
            return PresetPhaseDefinition(cycle: cycle, roundCount: 1)
        }

        return nil
    }

    static func encodePresetPhases(cycle: [PresetPhaseItem], roundCount: Int) -> String {
        let payload = PresetPhasesPayloadV2(
            version: 2,
            cycle: cycle,
            roundCount: max(WorkoutPreset.minRoundCount, roundCount)
        )
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return encodePhases(cycle)
        }
        return json
    }

    static func encodePreset(_ preset: WorkoutPreset) -> String {
        encodePresetPhases(cycle: preset.phases, roundCount: preset.roundCount)
    }

    /// v1 flat array decode (legacy callers).
    static func decodePhases(from json: String) -> [PresetPhaseItem]? {
        decodePresetDefinition(from: json)?.cycle
    }

    /// v1 flat array encode (legacy callers).
    static func encodePhases(_ phases: [PresetPhaseItem]) -> String {
        guard let data = try? JSONEncoder().encode(phases),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
