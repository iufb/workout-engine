import Foundation
import SwiftData

@Model
final class StoredPreset {
    @Attribute(.unique) var id: UUID
    var name: String
    var phasesJSON: String
    var isBuiltIn: Bool
    var cachedTotalDuration: Double = 0
    var cachedExpandedPhaseCount: Int = 0

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
        let normalized = preset.normalized()
        let metrics = WorkoutPreset.computeMetrics(
            phases: normalized.phases,
            roundCount: normalized.roundCount
        )
        self.init(
            id: normalized.id,
            name: normalized.name,
            phasesJSON: PresetMigration.encodePreset(normalized),
            isBuiltIn: normalized.isBuiltIn,
            rounds: normalized.roundCount
        )
        cachedTotalDuration = metrics.totalDuration
        cachedExpandedPhaseCount = metrics.expandedPhaseCount
    }

    func toWorkoutPreset() -> WorkoutPreset {
        let definition = resolvedDefinition()
        refreshCachedMetricsIfNeeded(definition: definition)
        return WorkoutPreset(
            id: id,
            name: name,
            phases: definition.cycle,
            roundCount: definition.roundCount,
            isBuiltIn: isBuiltIn,
            cachedTotalDuration: cachedTotalDuration > 0 ? cachedTotalDuration : nil,
            cachedExpandedPhaseCount: cachedExpandedPhaseCount > 0 ? cachedExpandedPhaseCount : nil
        )
    }

    func update(from preset: WorkoutPreset) {
        let normalized = preset.normalized()
        name = normalized.name
        phasesJSON = PresetMigration.encodePreset(normalized)
        isBuiltIn = normalized.isBuiltIn
        rounds = normalized.roundCount
        let metrics = WorkoutPreset.computeMetrics(phases: normalized.phases, roundCount: normalized.roundCount)
        cachedTotalDuration = metrics.totalDuration
        cachedExpandedPhaseCount = metrics.expandedPhaseCount
    }

    private func refreshCachedMetricsIfNeeded(definition: PresetMigration.PresetPhaseDefinition) {
        guard cachedTotalDuration <= 0 || cachedExpandedPhaseCount <= 0 else { return }
        let metrics = WorkoutPreset.computeMetrics(phases: definition.cycle, roundCount: definition.roundCount)
        cachedTotalDuration = metrics.totalDuration
        cachedExpandedPhaseCount = metrics.expandedPhaseCount
    }

    func resolvedDefinition() -> PresetMigration.PresetPhaseDefinition {
        if let decoded = PresetMigration.decodePresetDefinition(from: phasesJSON) {
            return decoded
        }
        if rounds > 0 || prepareSeconds > 0 || workSeconds > 0 {
            let legacy = PresetMigration.phasesFromLegacy(
                rounds: rounds,
                prepareSeconds: prepareSeconds,
                workSeconds: workSeconds,
                restSeconds: restSeconds
            )
            return PresetMigration.PresetPhaseDefinition(cycle: legacy, roundCount: 1)
        }
        let defaultPreset = WorkoutPreset.defaultNew()
        return PresetMigration.PresetPhaseDefinition(
            cycle: defaultPreset.phases,
            roundCount: defaultPreset.roundCount
        )
    }

    func resolvedPhases() -> [PresetPhaseItem] {
        resolvedDefinition().cycle
    }

    func migratePhasesIfNeeded() {
        if PresetMigration.decodePresetDefinition(from: phasesJSON) != nil {
            return
        }
        let migrated = resolvedDefinition()
        phasesJSON = PresetMigration.encodePresetPhases(
            cycle: migrated.cycle,
            roundCount: migrated.roundCount
        )
    }
}
