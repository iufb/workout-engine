import Foundation
@testable import workout_engine

extension WorkoutPreset {
    /// Classic 20/10 × 8 — used in unit tests only (not seeded in the app).
    static let tabataSample = WorkoutPreset(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
        name: "Tabata",
        phases: [
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ],
        roundCount: 8
    )
}
