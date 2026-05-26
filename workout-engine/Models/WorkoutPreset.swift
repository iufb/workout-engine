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
    static let minRoundCount = 1
    static let maxRoundCount = 99

    let id: UUID
    var name: String
    /// One cycle template (edited in the constructor).
    var phases: [PresetPhaseItem]
    var roundCount: Int
    var isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        phases: [PresetPhaseItem],
        roundCount: Int = 1,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phases = phases
        self.roundCount = Self.clampedRoundCount(roundCount)
        self.isBuiltIn = isBuiltIn
    }

    static func defaultNew(name: String? = nil) -> WorkoutPreset {
        WorkoutPreset(
            name: name ?? L10n.t("Мой интервал"),
            phases: [
                PresetPhaseItem(kind: .prepare, durationSeconds: 10),
                PresetPhaseItem(kind: .work, durationSeconds: 20),
                PresetPhaseItem(kind: .rest, durationSeconds: 10),
            ],
            roundCount: 1
        )
    }

    var expandedPhases: [PresetPhaseItem] {
        PresetCycleExpander.expand(cycle: phases, roundCount: roundCount)
    }

    var estimatedTotalDuration: TimeInterval {
        expandedPhases.reduce(0) { $0 + TimeInterval(max(0, $1.durationSeconds)) }
    }

    var phaseCount: Int { expandedPhases.count }

    func normalized() -> WorkoutPreset {
        var copy = self
        copy.phases = phases.map { phase in
            var p = phase
            let range = phase.kind == .prepare ? 0 ... 3600 : 1 ... 3600
            p.durationSeconds = min(max(p.durationSeconds, range.lowerBound), range.upperBound)
            return p
        }
        copy.roundCount = Self.clampedRoundCount(roundCount)
        return copy
    }

    private static func clampedRoundCount(_ value: Int) -> Int {
        min(maxRoundCount, max(minRoundCount, value))
    }

    enum CodingKeys: String, CodingKey {
        case id, name, phases, roundCount, isBuiltIn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        phases = try container.decode([PresetPhaseItem].self, forKey: .phases)
        roundCount = Self.clampedRoundCount(try container.decodeIfPresent(Int.self, forKey: .roundCount) ?? 1)
        isBuiltIn = try container.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(phases, forKey: .phases)
        try container.encode(roundCount, forKey: .roundCount)
        try container.encode(isBuiltIn, forKey: .isBuiltIn)
    }
}
