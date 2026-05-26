import Foundation
import SwiftData

@Model
final class StoredPreset {
    @Attribute(.unique) var id: UUID
    var name: String
    var phasesJSON: String
    var isBuiltIn: Bool

    // Legacy fields kept for migration from v1 schema.
    var rounds: Int
    var prepareSeconds: Double
    var workSeconds: Double
    var restSeconds: Double

    init(
        id: UUID = UUID(),
        name: String,
        phasesJSON: String = "",
        isBuiltIn: Bool = false,
        rounds: Int = 0,
        prepareSeconds: Double = 0,
        workSeconds: Double = 0,
        restSeconds: Double = 0
    ) {
        self.id = id
        self.name = name
        self.phasesJSON = phasesJSON
        self.isBuiltIn = isBuiltIn
        self.rounds = rounds
        self.prepareSeconds = prepareSeconds
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
    }

    convenience init(from preset: WorkoutPreset) {
        self.init(
            id: preset.id,
            name: preset.name,
            phasesJSON: PresetMigration.encodePhases(preset.phases),
            isBuiltIn: preset.isBuiltIn
        )
    }

    func toWorkoutPreset() -> WorkoutPreset {
        let phases = resolvedPhases()
        return WorkoutPreset(
            id: id,
            name: name,
            phases: phases,
            isBuiltIn: isBuiltIn
        )
    }

    func update(from preset: WorkoutPreset) {
        name = preset.name
        phasesJSON = PresetMigration.encodePhases(preset.phases)
        isBuiltIn = preset.isBuiltIn
    }

    func resolvedPhases() -> [PresetPhaseItem] {
        if let decoded = PresetMigration.decodePhases(from: phasesJSON), !decoded.isEmpty {
            return decoded
        }
        if rounds > 0 || prepareSeconds > 0 || workSeconds > 0 {
            return PresetMigration.phasesFromLegacy(
                rounds: rounds,
                prepareSeconds: prepareSeconds,
                workSeconds: workSeconds,
                restSeconds: restSeconds
            )
        }
        return WorkoutPreset.defaultNew().phases
    }

    func migratePhasesIfNeeded() {
        if let decoded = PresetMigration.decodePhases(from: phasesJSON), !decoded.isEmpty {
            return
        }
        let migrated = resolvedPhases()
        phasesJSON = PresetMigration.encodePhases(migrated)
    }
}
