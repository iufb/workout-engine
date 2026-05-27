import XCTest
@testable import workout_engine

@MainActor
final class WorkoutEngineCountdownTests: XCTestCase {
    private var engine: WorkoutEngine!
    private var mockFeedback: MockWorkoutFeedback!

    override func setUp() {
        engine = WorkoutEngine()
        mockFeedback = MockWorkoutFeedback()
        engine.feedbackHandler = mockFeedback
    }

    func testCountdownAnnouncesThreeTwoOneOnceEach() {
        let start = Date()
        engine.load(
            preset: WorkoutPreset(
                name: "C",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 10)]
            )
        )
        engine.start(sessionStart: start)

        engine.tick(now: start.addingTimeInterval(7.2))
        engine.tick(now: start.addingTimeInterval(7.0))
        engine.tick(now: start.addingTimeInterval(8.1))
        engine.tick(now: start.addingTimeInterval(9.1))

        XCTAssertEqual(mockFeedback.countdownSeconds, [3, 2, 1])
    }

    func testCountdownDoesNotFireAboveThreeSeconds() {
        let start = Date()
        engine.load(
            preset: WorkoutPreset(
                name: "C",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 10)]
            )
        )
        engine.start(sessionStart: start)

        engine.tick(now: start.addingTimeInterval(5.0))
        XCTAssertTrue(mockFeedback.countdownSeconds.isEmpty)
    }

    func testCountdownResetsAfterPhaseAdvance() {
        let start = Date()
        engine.load(
            preset: WorkoutPreset(
                name: "C",
                phases: [
                    PresetPhaseItem(kind: .prepare, durationSeconds: 5),
                    PresetPhaseItem(kind: .work, durationSeconds: 10),
                ]
            )
        )
        engine.start(sessionStart: start)

        engine.tick(now: start.addingTimeInterval(2.1))
        engine.tick(now: start.addingTimeInterval(3.1))
        engine.tick(now: start.addingTimeInterval(4.1))
        XCTAssertEqual(mockFeedback.countdownSeconds, [3, 2, 1])

        mockFeedback.countdownSeconds.removeAll()
        engine.tick(now: start.addingTimeInterval(5.0))
        engine.tick(now: start.addingTimeInterval(12.0))
        XCTAssertEqual(mockFeedback.countdownSeconds, [3])
    }

    func testPauseStopsCountdownUntilResume() {
        let start = Date()
        engine.load(
            preset: WorkoutPreset(
                name: "C",
                phases: [PresetPhaseItem(kind: .work, durationSeconds: 10)]
            )
        )
        engine.start(sessionStart: start)

        engine.tick(now: start.addingTimeInterval(7.5))
        XCTAssertEqual(mockFeedback.countdownSeconds, [3])

        mockFeedback.countdownSeconds.removeAll()
        engine.pause()
        engine.tick(now: start.addingTimeInterval(8.0))
        XCTAssertTrue(mockFeedback.countdownSeconds.isEmpty)

        engine.resume()
        let resumeTime = start.addingTimeInterval(7.5)
        engine.tick(now: resumeTime.addingTimeInterval(1.0))
        engine.tick(now: resumeTime.addingTimeInterval(2.0))
        XCTAssertEqual(mockFeedback.countdownSeconds, [2, 1])
    }
}

@MainActor
private final class MockWorkoutFeedback: WorkoutFeedbackHandling {
    var countdownSeconds: [Int] = []

    func workoutEngine(_ engine: WorkoutEngine, didEnterPhase step: PhaseStep, at index: Int) {}

    func workoutEngine(_ engine: WorkoutEngine, didCompletePhase step: PhaseStep, at index: Int) {}

    func workoutEngine(_ engine: WorkoutEngine, countdownSecond second: Int, for phase: PhaseStep) {
        countdownSeconds.append(second)
    }

    func workoutEngineDidFinish(_ engine: WorkoutEngine) {}

    func workoutEngineDidStop(_ engine: WorkoutEngine) {}
}
