import XCTest
@testable import workout_engine

final class WorkoutPresetTests: XCTestCase {
    func testDefaultNewHasThreePhases() {
        let preset = WorkoutPreset.defaultNew()
        XCTAssertEqual(preset.phases.count, 3)
        XCTAssertEqual(preset.phases.map(\.kind), [.prepare, .work, .rest])
        XCTAssertEqual(preset.phases[0].durationSeconds, 10)
        XCTAssertEqual(preset.phases[1].durationSeconds, 20)
        XCTAssertEqual(preset.phases[2].durationSeconds, 10)
    }

    func testTabataExpandedPhaseCount() {
        XCTAssertEqual(WorkoutPreset.makeTabataPhases().count, 16)
        XCTAssertEqual(WorkoutPreset.tabata.phaseCount, 16)
    }

    func testLegacyMigrationMatchesTabataShape() {
        let legacy = PresetMigration.phasesFromLegacy(
            rounds: 8,
            prepareSeconds: 10,
            workSeconds: 20,
            restSeconds: 10
        )
        XCTAssertEqual(legacy.count, 16)
        XCTAssertEqual(legacy.map(\.kind), WorkoutPreset.tabata.phases.map(\.kind))
    }
}
