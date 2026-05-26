import Foundation

struct PhaseStep: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var kind: PhaseKind
    var duration: TimeInterval
    var round: Int?

    init(id: UUID = UUID(), kind: PhaseKind, duration: TimeInterval, round: Int? = nil) {
        self.id = id
        self.kind = kind
        self.duration = duration
        self.round = round
    }
}

struct WorkoutPreset: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var phases: [PresetPhaseItem]
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        phases: [PresetPhaseItem],
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phases = phases
        self.isBuiltIn = isBuiltIn
    }

    static let tabataID = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!

    static let tabata = WorkoutPreset(
        id: tabataID,
        name: String(localized: "Tabata"),
        phases: makeTabataPhases(),
        isBuiltIn: true
    )

    static func defaultNew(name: String? = nil) -> WorkoutPreset {
        WorkoutPreset(
            name: name ?? String(localized: "Мой интервал"),
            phases: [
                PresetPhaseItem(kind: .prepare, durationSeconds: 10),
                PresetPhaseItem(kind: .work, durationSeconds: 20),
                PresetPhaseItem(kind: .rest, durationSeconds: 10),
            ]
        )
    }

    /// Tabata: prepare + 8×(work, rest) without rest after final work → 16 phases.
    static func makeTabataPhases() -> [PresetPhaseItem] {
        var items: [PresetPhaseItem] = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
        ]
        for round in 1 ... 8 {
            items.append(PresetPhaseItem(kind: .work, durationSeconds: 20))
            if round < 8 {
                items.append(PresetPhaseItem(kind: .rest, durationSeconds: 10))
            }
        }
        return items
    }

    var estimatedTotalDuration: TimeInterval {
        phases.reduce(0) { $0 + TimeInterval(max(0, $1.durationSeconds)) }
    }

    var phaseCount: Int { phases.count }

    func normalized() -> WorkoutPreset {
        var copy = self
        copy.phases = phases.map { phase in
            var p = phase
            let range = phase.kind == .prepare ? 0 ... 3600 : 1 ... 3600
            p.durationSeconds = min(max(p.durationSeconds, range.lowerBound), range.upperBound)
            return p
        }
        return copy
    }
}
