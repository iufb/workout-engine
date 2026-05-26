import Foundation
import SwiftData

@MainActor
final class PresetStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<StoredPreset>()
        let existing = try modelContext.fetch(descriptor)
        for stored in existing {
            stored.migratePhasesIfNeeded()
            if stored.isBuiltIn {
                if AppSettings.shared.lastUsedPresetID == stored.id {
                    AppSettings.shared.lastUsedPresetID = nil
                }
                modelContext.delete(stored)
            }
        }
        try modelContext.save()
    }

    func fetchAll() throws -> [WorkoutPreset] {
        let stored = try modelContext.fetch(FetchDescriptor<StoredPreset>())
        for item in stored {
            item.migratePhasesIfNeeded()
        }
        try modelContext.save()
        return stored
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .map { $0.toWorkoutPreset() }
    }

    func save(_ preset: WorkoutPreset) throws {
        let normalized = preset.normalized()
        let id = normalized.id
        var descriptor = FetchDescriptor<StoredPreset>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        if let stored = try modelContext.fetch(descriptor).first {
            stored.update(from: normalized)
        } else {
            modelContext.insert(StoredPreset(from: normalized))
        }
        try modelContext.save()
    }

    func delete(_ preset: WorkoutPreset) throws {
        let targetID = preset.id
        var descriptor = FetchDescriptor<StoredPreset>(predicate: #Predicate { $0.id == targetID })
        descriptor.fetchLimit = 1
        if let stored = try modelContext.fetch(descriptor).first {
            modelContext.delete(stored)
            try modelContext.save()
        }
    }
}
