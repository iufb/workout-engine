import XCTest
@testable import workout_engine

@MainActor
final class WorkoutEngineTests: XCTestCase {
    func testStartAndFinishAfterAllPhases() {
        let engine = WorkoutEngine()
        let preset = WorkoutPreset(
            name: "Tiny",
            phases: [
                PresetPhaseItem(kind: .prepare, durationSeconds: 1),
                PresetPhaseItem(kind: .work, durationSeconds: 1),
            ]
        )
        engine.load(preset: preset)
        engine.start()

        XCTAssertEqual(engine.status, .running)
        XCTAssertEqual(engine.currentPhase?.kind, .prepare)

        engine.tick(now: Date().addingTimeInterval(1.1))
        XCTAssertEqual(engine.currentPhase?.kind, .work)

        engine.tick(now: Date().addingTimeInterval(2.2))
        XCTAssertEqual(engine.status, .finished)
    }

    func testPauseResumePreservesRemaining() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "P",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 10)]
            )
        )
        engine.start()

        engine.pause()
        let remainingAtPause = engine.remaining
        XCTAssertGreaterThan(remainingAtPause, 8)

        engine.resume()
        XCTAssertEqual(engine.status, .running)
        XCTAssertLessThanOrEqual(engine.remaining, remainingAtPause + 0.5)
    }

    func testSkipAdvancesPhase() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "S",
                phases: [
                    PresetPhaseItem(kind: .prepare, durationSeconds: 30),
                    PresetPhaseItem(kind: .work, durationSeconds: 30),
                ]
            )
        )
        engine.start()
        XCTAssertEqual(engine.currentPhase?.kind, .prepare)

        engine.skipPhase()
        XCTAssertEqual(engine.currentPhase?.kind, .work)
    }

    func testStopReturnsToIdle() {
        let engine = WorkoutEngine()
        engine.load(preset: .tabataSample)
        engine.start()
        engine.stop()
        XCTAssertEqual(engine.status, .idle)
    }

    func testPhaseNumberTracking() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "N",
                phases: [
                    PresetPhaseItem(kind: .work, durationSeconds: 5),
                    PresetPhaseItem(kind: .rest, durationSeconds: 5),
                    PresetPhaseItem(kind: .work, durationSeconds: 5),
                ]
            )
        )
        engine.start()
        XCTAssertEqual(engine.currentPhaseNumber, 1)
        XCTAssertEqual(engine.totalPhaseCount, 3)
    }

    func testRemainingAtDecreasesOverTime() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "T",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 30)]
            )
        )
        engine.start()

        let start = Date()
        let initial = engine.remaining(at: start)
        let later = engine.remaining(at: start.addingTimeInterval(5))

        XCTAssertEqual(initial, 30, accuracy: 0.5)
        XCTAssertEqual(later, 25, accuracy: 0.5)
        XCTAssertLessThan(later, initial)
    }

    func testProgressAtIncreasesDuringPhase() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "T",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 10)]
            )
        )
        engine.start()

        let start = Date()
        let early = engine.progress(at: start)
        let later = engine.progress(at: start.addingTimeInterval(5))

        XCTAssertLessThan(early, later)
        XCTAssertLessThanOrEqual(later, 1)
    }

    func testCurrentPhaseProgressAt() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "T",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 20)]
            )
        )
        engine.start()

        let start = Date()
        XCTAssertEqual(engine.currentPhaseProgress(at: start), 0, accuracy: 0.01)
        XCTAssertEqual(engine.currentPhaseProgress(at: start.addingTimeInterval(10)), 0.5, accuracy: 0.05)
    }
}
