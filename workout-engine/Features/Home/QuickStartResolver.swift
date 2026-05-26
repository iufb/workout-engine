import Foundation

enum QuickStartResolver {
    /// Resolves the preset for quick start: last used if still available, otherwise the first saved preset.
    static func resolve(presets: [WorkoutPreset], lastUsedID: UUID?) -> WorkoutPreset? {
        if let lastUsedID,
           let last = presets.first(where: { $0.id == lastUsedID }) {
            return last
        }
        return presets.first
    }

    /// Whether quick start is showing the last-used preset (vs first available fallback).
    static func isLastUsed(preset: WorkoutPreset, lastUsedID: UUID?) -> Bool {
        guard let lastUsedID else { return false }
        return preset.id == lastUsedID
    }
}
