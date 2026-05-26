import AVFoundation

@MainActor
final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private(set) var isActive = false

    /// Called when the system ends an audio interruption and playback may resume.
    var onInterruptionEnded: (@MainActor () -> Void)?

    private var observersInstalled = false
    private var observationTokens: [NSObjectProtocol] = []

    private init() {}

    func activateForWorkout() throws {
        installObserversIfNeeded()
        let session = AVAudioSession.sharedInstance()
        // Avoid .mixWithOthers so workout cues stay audible over the silent keep-alive loop.
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        isActive = true
    }

    func deactivate() {
        guard isActive else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isActive = false
    }

    private func installObserversIfNeeded() {
        guard !observersInstalled else { return }
        observersInstalled = true

        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()

        observationTokens.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    self?.handleInterruption(notification)
                }
            }
        )

        observationTokens.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    self?.handleRouteChange(notification)
                }
            }
        )
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            isActive = false
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            guard options.contains(.shouldResume) else { return }
            do {
                try activateForWorkout()
                onInterruptionEnded?()
            } catch {
                // Session may stay inactive until the next workout start.
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        switch reason {
        case .oldDeviceUnavailable:
            guard isActive else { return }
            SoundPlayer.shared.startSessionAudio()
        default:
            break
        }
    }
}
