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
        guard existing.isEmpty else {
            for stored in existing {
                stored.migratePhasesIfNeeded()
            }
            try modelContext.save()
            return
        }

        let tabata = StoredPreset(from: .tabata)
        modelContext.insert(tabata)
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
                if lhs.isBuiltIn != rhs.isBuiltIn {
                    return lhs.isBuiltIn && !rhs.isBuiltIn
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
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
        guard !preset.isBuiltIn else { return }
        let targetID = preset.id
        var descriptor = FetchDescriptor<StoredPreset>(predicate: #Predicate { $0.id == targetID })
        descriptor.fetchLimit = 1
        if let stored = try modelContext.fetch(descriptor).first {
            modelContext.delete(stored)
            try modelContext.save()
        }
    }

    func resetTabataToDefault() throws {
        let builtInID = WorkoutPreset.tabataID
        var descriptor = FetchDescriptor<StoredPreset>(predicate: #Predicate { $0.id == builtInID })
        descriptor.fetchLimit = 1
        if let stored = try modelContext.fetch(descriptor).first {
            stored.update(from: .tabata)
            try modelContext.save()
        }
    }
}
