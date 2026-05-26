import XCTest
@testable import workout_engine

final class WorkoutPresetTests: XCTestCase {
    func testDefaultNewHasThreePhaseCycleAndOneRound() {
        let preset = WorkoutPreset.defaultNew()
        XCTAssertEqual(preset.phases.count, 3)
        XCTAssertEqual(preset.roundCount, 1)
        XCTAssertEqual(preset.phases.map(\.kind), [.prepare, .work, .rest])
        XCTAssertEqual(preset.phases[0].durationSeconds, 10)
        XCTAssertEqual(preset.phases[1].durationSeconds, 20)
        XCTAssertEqual(preset.phases[2].durationSeconds, 10)
        XCTAssertEqual(preset.phaseCount, 3)
    }

    func testTabataCycleAndExpandedPhaseCount() {
        XCTAssertEqual(WorkoutPreset.tabataSample.phases.count, 2)
        XCTAssertEqual(WorkoutPreset.tabataSample.roundCount, 8)
        XCTAssertEqual(WorkoutPreset.tabataSample.phaseCount, 15)
        XCTAssertEqual(WorkoutPreset.tabataSample.expandedPhases.count, 15)
    }

    func testLegacyMigrationMatchesTabataExpandedShape() {
        let legacy = PresetMigration.phasesFromLegacy(
            rounds: 8,
            prepareSeconds: 10,
            workSeconds: 20,
            restSeconds: 10
        )
        XCTAssertEqual(legacy.count, 16)
        let tabataExpanded = WorkoutPreset.tabataSample.expandedPhases
        XCTAssertEqual(tabataExpanded.filter { $0.kind == .work }.count, 8)
        XCTAssertEqual(tabataExpanded.filter { $0.kind == .rest }.count, 7)
        XCTAssertEqual(tabataExpanded.last?.kind, .work)
    }
}
