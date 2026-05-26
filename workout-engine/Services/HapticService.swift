import UIKit

final class HapticService {
    static let shared = HapticService()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    func phaseTransition(for kind: PhaseKind) {
        guard AppSettings.shared.hapticsEnabled else { return }
        switch kind {
        case .prepare:
            light.impactOccurred()
        case .work:
            heavy.impactOccurred()
        case .rest:
            medium.impactOccurred()
        }
    }

    func workoutFinished() {
        guard AppSettings.shared.hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }

    func workoutStopped() {
        guard AppSettings.shared.hapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }
}
