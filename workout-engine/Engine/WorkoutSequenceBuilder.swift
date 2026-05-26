import Foundation

enum WorkoutSequenceBuilder {
    static func sequence(for preset: WorkoutPreset) -> [PhaseStep] {
        preset.phases
            .filter { $0.durationSeconds > 0 }
            .map { PhaseStep(kind: $0.kind, duration: TimeInterval($0.durationSeconds)) }
    }
}
