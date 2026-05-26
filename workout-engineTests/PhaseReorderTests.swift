import XCTest
@testable import workout_engine

final class PhaseReorderTests: XCTestCase {
    func testMovePhaseBeforeTarget() {
        var phases = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ]
        let dragged = phases[2].id
        let target = phases[0].id

        XCTAssertTrue(PhaseReorder.move(phases: &phases, draggedID: dragged, before: target))
        XCTAssertEqual(phases.map(\.kind), [.rest, .prepare, .work])
    }

    func testMoveToIndex() {
        var phases = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ]
        let dragged = phases[0].id

        XCTAssertTrue(PhaseReorder.moveToIndex(phases: &phases, draggedID: dragged, to: 2))
        XCTAssertEqual(phases.map(\.kind), [.work, .rest, .prepare])
    }

    func testTargetIndexWhenDraggingDown() {
        let phases = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ]
        let frames: [UUID: CGRect] = [
            phases[0].id: CGRect(x: 0, y: 0, width: 320, height: 88),
            phases[1].id: CGRect(x: 0, y: 100, width: 320, height: 88),
            phases[2].id: CGRect(x: 0, y: 200, width: 320, height: 88),
        ]

        let target = PhaseReorder.targetIndex(
            dragCenterY: 150,
            draggedID: phases[0].id,
            in: phases,
            rowFrames: frames
        )

        XCTAssertEqual(target, 1)
    }

    func testTargetIndexWhenDraggingUp() {
        let phases = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
            PresetPhaseItem(kind: .rest, durationSeconds: 10),
        ]
        let frames: [UUID: CGRect] = [
            phases[0].id: CGRect(x: 0, y: 0, width: 320, height: 88),
            phases[1].id: CGRect(x: 0, y: 100, width: 320, height: 88),
            phases[2].id: CGRect(x: 0, y: 200, width: 320, height: 88),
        ]

        let target = PhaseReorder.targetIndex(
            dragCenterY: 50,
            draggedID: phases[2].id,
            in: phases,
            rowFrames: frames
        )

        XCTAssertEqual(target, 1)
    }

    func testTargetIndexReturnsNilWhenNotCrossingMidpoint() {
        let phases = [
            PresetPhaseItem(kind: .prepare, durationSeconds: 10),
            PresetPhaseItem(kind: .work, durationSeconds: 20),
        ]
        let frames: [UUID: CGRect] = [
            phases[0].id: CGRect(x: 0, y: 0, width: 320, height: 88),
            phases[1].id: CGRect(x: 0, y: 100, width: 320, height: 88),
        ]

        let target = PhaseReorder.targetIndex(
            dragCenterY: 40,
            draggedID: phases[0].id,
            in: phases,
            rowFrames: frames
        )

        XCTAssertNil(target)
    }
}
