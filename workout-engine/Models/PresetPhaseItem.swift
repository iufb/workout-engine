import Foundation

struct PresetPhaseItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var kind: PhaseKind
    var durationSeconds: Int

    init(id: UUID = UUID(), kind: PhaseKind, durationSeconds: Int) {
        self.id = id
        self.kind = kind
        self.durationSeconds = durationSeconds
    }

    static let defaultDuration = 30

    static func make(kind: PhaseKind, durationSeconds: Int? = nil) -> PresetPhaseItem {
        let duration = durationSeconds ?? defaultDuration
        return PresetPhaseItem(kind: kind, durationSeconds: duration)
    }
}
