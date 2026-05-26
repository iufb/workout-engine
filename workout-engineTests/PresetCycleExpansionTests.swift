import XCTest
@testable import workout_engine

final class PresetCycleExpansionTests: XCTestCase {
    func testSingleRoundKeepsTrailingRest() {
        let cycle = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ]
        let expanded = PresetCycleExpander.expand(cycle: cycle, roundCount: 1)
        XCTAssertEqual(expanded.count, 3)
        XCTAssertEqual(expanded.map(\.kind), [.prepare, .work, .rest])
    }

    func testMultipleRoundsOmitLastRest() {
        let cycle = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ]
        let expanded = PresetCycleExpander.expand(cycle: cycle, roundCount: 4)
        XCTAssertEqual(expanded.count, 11)
        XCTAssertEqual(expanded.last?.kind, .work)
        XCTAssertEqual(expanded.filter { $0.kind == .rest }.count, 3)
    }

    func testTabataCycleExpansion() {
        let preset = WorkoutPreset.tabataSample
        XCTAssertEqual(preset.phases.count, 2)
        XCTAssertEqual(preset.roundCount, 8)
        XCTAssertEqual(preset.expandedPhases.count, 15)
        XCTAssertEqual(preset.expandedPhases.filter { $0.kind == .work }.count, 8)
        XCTAssertEqual(preset.expandedPhases.filter { $0.kind == .rest }.count, 7)
        XCTAssertEqual(preset.expandedPhases.last?.kind, .work)
    }

    func testEmptyCycleReturnsEmpty() {
        XCTAssertTrue(PresetCycleExpander.expand(cycle: [], roundCount: 5).isEmpty)
    }

    func testMigrationV2RoundTrip() {
        let preset = WorkoutPreset(
            name: "Test",
            phases: [
                PresetPhaseItem(kind: .work, durationSeconds: 30),
                PresetPhaseItem(kind: .rest, durationSeconds: 15),
            ],
            roundCount: 5
        )
        let json = PresetMigration.encodePreset(preset)
        let decoded = PresetMigration.decodePresetDefinition(from: json)
        XCTAssertEqual(decoded?.cycle.count, 2)
        XCTAssertEqual(decoded?.roundCount, 5)
    }

    func testMigrationV1FlatArrayUsesSingleRound() {
        let json = PresetMigration.encodePhases([
            PresetPhaseItem(kind: .work, durationSeconds: 10),
            PresetPhaseItem(kind: .rest, durationSeconds: 5),
        ])
        let decoded = PresetMigration.decodePresetDefinition(from: json)
        XCTAssertEqual(decoded?.cycle.count, 2)
        XCTAssertEqual(decoded?.roundCount, 1)
    }
}
