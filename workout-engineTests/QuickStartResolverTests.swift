import XCTest
@testable import workout_engine

final class QuickStartResolverTests: XCTestCase {
    private let tabata = WorkoutPreset.tabata
    private lazy var custom = WorkoutPreset(
        name: "Custom",
        phases: WorkoutPreset.defaultNew().phases,
        isBuiltIn: false
    )

    func testResolveReturnsLastUsedWhenPresent() {
        let presets = [tabata, custom]
        let resolved = QuickStartResolver.resolve(presets: presets, lastUsedID: custom.id)
        XCTAssertEqual(resolved?.id, custom.id)
    }

    func testResolveFallsBackToBuiltInWhenLastUsedMissing() {
        let presets = [tabata, custom]
        let unknownID = UUID()
        let resolved = QuickStartResolver.resolve(presets: presets, lastUsedID: unknownID)
        XCTAssertEqual(resolved?.id, tabata.id)
    }

    func testResolveFallsBackToBuiltInWhenLastUsedNil() {
        let presets = [tabata, custom]
        let resolved = QuickStartResolver.resolve(presets: presets, lastUsedID: nil)
        XCTAssertEqual(resolved?.id, tabata.id)
    }

    func testIsLastUsed() {
        XCTAssertTrue(QuickStartResolver.isLastUsed(preset: custom, lastUsedID: custom.id))
        XCTAssertFalse(QuickStartResolver.isLastUsed(preset: tabata, lastUsedID: custom.id))
        XCTAssertFalse(QuickStartResolver.isLastUsed(preset: tabata, lastUsedID: nil))
    }
}
