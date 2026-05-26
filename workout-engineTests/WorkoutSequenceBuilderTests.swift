import XCTest
@testable import workout_engine

final class WorkoutSequenceBuilderTests: XCTestCase {
    func testTabataSequencePhaseCount() {
        let preset = WorkoutPreset.tabataSample
        let sequence = WorkoutSequenceBuilder.sequence(for: preset)

        XCTAssertEqual(preset.expandedPhases.count, 15)
        XCTAssertEqual(sequence.count, 15)
        XCTAssertEqual(sequence.filter { $0.kind == .work }.count, 8)
        XCTAssertEqual(sequence.filter { $0.kind == .rest }.count, 7)
        XCTAssertEqual(sequence.last?.kind, .work)
    }

    func testExpandedOrderForMultiRoundCycle() {
        let preset = WorkoutPreset(
            name: "Custom",
            phases: [
                PresetPhaseItem(kind: .work, durationSeconds: 10),
                PresetPhaseItem(kind: .rest, durationSeconds: 5),
            ],
            roundCount: 3
        )
        let sequence = WorkoutSequenceBuilder.sequence(for: preset)
        XCTAssertEqual(sequence.map(\.kind), [.work, .rest, .work, .rest, .work])
    }

    func testZeroDurationPhasesFiltered() {
        let preset = WorkoutPreset(
            name: "Skip zero",
            phases: [
                PresetPhaseItem(kind: .prepare, durationSeconds: 0),
                PresetPhaseItem(kind: .work, durationSeconds: 10),
            ],
            roundCount: 1
        )
        let sequence = WorkoutSequenceBuilder.sequence(for: preset)
        XCTAssertEqual(sequence.count, 1)
        XCTAssertEqual(sequence.first?.kind, .work)
    }
}
