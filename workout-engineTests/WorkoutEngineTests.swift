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
        let start = Date()
        engine.start(sessionStart: start)

        XCTAssertEqual(engine.status, .running)
        XCTAssertEqual(engine.currentPhase?.kind, .prepare)

        engine.tick(now: start.addingTimeInterval(1.1))
        XCTAssertEqual(engine.currentPhase?.kind, .work)

        engine.tick(now: start.addingTimeInterval(2.2))
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

    func testPhasePositionLabelForMultiRoundPreset() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "Rounds",
                phases: [
                    PresetPhaseItem(kind: .work, durationSeconds: 5),
                    PresetPhaseItem(kind: .rest, durationSeconds: 5),
                ],
                roundCount: 2
            )
        )
        engine.start()
        XCTAssertEqual(
            engine.phasePositionLabel,
            L10n.t("Круг \(1) / \(2) · Фаза \(1) / \(2)")
        )
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
        let start = Date()
        engine.start(sessionStart: start)

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
        let start = Date()
        engine.start(sessionStart: start)

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
        let start = Date()
        engine.start(sessionStart: start)

        XCTAssertEqual(engine.currentPhaseProgress(at: start), 0, accuracy: 0.01)
        XCTAssertEqual(engine.currentPhaseProgress(at: start.addingTimeInterval(10)), 0.5, accuracy: 0.05)
    }

    func testSyncSkipsMultiplePhases() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "Sync",
                phases: [
                    PresetPhaseItem(kind: .prepare, durationSeconds: 2),
                    PresetPhaseItem(kind: .work, durationSeconds: 2),
                    PresetPhaseItem(kind: .rest, durationSeconds: 2),
                ]
            )
        )
        let start = Date()
        engine.start(sessionStart: start)

        engine.syncToWallClock(now: start.addingTimeInterval(5.5))
        XCTAssertEqual(engine.currentPhaseIndex, 2)
        XCTAssertEqual(engine.currentPhase?.kind, .rest)
        XCTAssertEqual(engine.remaining(at: start.addingTimeInterval(5.5)), 0.5, accuracy: 0.1)

        engine.syncToWallClock(now: start.addingTimeInterval(7))
        XCTAssertEqual(engine.status, .finished)
    }

    func testSyncMidPhaseRemaining() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "Mid",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 30)]
            )
        )
        let start = Date()
        engine.start(sessionStart: start)

        let mid = start.addingTimeInterval(15)
        engine.syncToWallClock(now: mid)
        XCTAssertEqual(engine.remaining(at: mid), 15, accuracy: 0.5)
    }

    func testPauseExcludedFromElapsed() {
        let engine = WorkoutEngine()
        engine.load(
            preset: WorkoutPreset(
                name: "Pause",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 30)]
            )
        )
        let start = Date()
        engine.start(sessionStart: start)

        engine.syncToWallClock(now: start.addingTimeInterval(5))
        let remainingBeforePause = engine.remaining
        XCTAssertEqual(remainingBeforePause, 25, accuracy: 0.5)

        engine.pause()
        Thread.sleep(forTimeInterval: 0.05)
        engine.resume()

        XCTAssertEqual(engine.remaining, remainingBeforePause, accuracy: 1.0)
    }
}
