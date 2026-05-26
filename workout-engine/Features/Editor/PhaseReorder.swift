import CoreGraphics
import Foundation

enum PhaseReorder {
    /// Moves the phase with `draggedID` to the position of `targetID`.
    static func move(
        phases: inout [PresetPhaseItem],
        draggedID: UUID,
        before targetID: UUID
    ) -> Bool {
        guard draggedID != targetID,
              let fromIndex = phases.firstIndex(where: { $0.id == draggedID }),
              let toIndex = phases.firstIndex(where: { $0.id == targetID }) else {
            return false
        }

        let item = phases.remove(at: fromIndex)
        let adjustedIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        phases.insert(item, at: adjustedIndex)
        return true
    }

    /// Moves the dragged phase to `targetIndex` when it differs from the current index.
    static func moveToIndex(
        phases: inout [PresetPhaseItem],
        draggedID: UUID,
        to targetIndex: Int
    ) -> Bool {
        guard let fromIndex = phases.firstIndex(where: { $0.id == draggedID }),
              fromIndex != targetIndex,
              phases.indices.contains(targetIndex) else {
            return false
        }

        let item = phases.remove(at: fromIndex)
        phases.insert(item, at: targetIndex)
        return true
    }

    /// Returns a new target index when the drag center crosses another row midpoint.
    static func targetIndex(
        dragCenterY: CGFloat,
        draggedID: UUID,
        in phases: [PresetPhaseItem],
        rowFrames: [UUID: CGRect]
    ) -> Int? {
        guard let fromIndex = phases.firstIndex(where: { $0.id == draggedID }) else {
            return nil
        }

        var targetIndex = fromIndex

        for index in phases.indices {
            let phase = phases[index]
            guard phase.id != draggedID,
                  let frame = rowFrames[phase.id] else { continue }

            if index < fromIndex, dragCenterY < frame.midY {
                return index
            }
            if index > fromIndex, dragCenterY > frame.midY {
                targetIndex = index
            }
        }

        return targetIndex == fromIndex ? nil : targetIndex
    }
}
