import XCTest
@testable import workout_engine

final class QuickStartResolverTests: XCTestCase {
    private lazy var alpha = WorkoutPreset(name: "Alpha", phases: WorkoutPreset.defaultNew().phases)
    private lazy var beta = WorkoutPreset(name: "Beta", phases: WorkoutPreset.defaultNew().phases)

    func testResolveReturnsLastUsedWhenPresent() {
        let presets = [alpha, beta]
        let resolved = QuickStartResolver.resolve(presets: presets, lastUsedID: beta.id)
        XCTAssertEqual(resolved?.id, beta.id)
    }

    func testResolveFallsBackToFirstPresetWhenLastUsedMissing() {
        let presets = [alpha, beta]
        let unknownID = UUID()
        let resolved = QuickStartResolver.resolve(presets: presets, lastUsedID: unknownID)
        XCTAssertEqual(resolved?.id, alpha.id)
    }

    func testResolveFallsBackToFirstPresetWhenLastUsedNil() {
        let presets = [alpha, beta]
        let resolved = QuickStartResolver.resolve(presets: presets, lastUsedID: nil)
        XCTAssertEqual(resolved?.id, alpha.id)
    }

    func testResolveReturnsNilWhenNoPresets() {
        XCTAssertNil(QuickStartResolver.resolve(presets: [], lastUsedID: nil))
    }

    func testIsLastUsed() {
        XCTAssertTrue(QuickStartResolver.isLastUsed(preset: beta, lastUsedID: beta.id))
        XCTAssertFalse(QuickStartResolver.isLastUsed(preset: alpha, lastUsedID: beta.id))
        XCTAssertFalse(QuickStartResolver.isLastUsed(preset: alpha, lastUsedID: nil))
    }
}
