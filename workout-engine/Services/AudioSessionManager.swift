import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private(set) var isActive = false

    private init() {}

    func activateForWorkout() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        isActive = true
    }

    func deactivate() {
        guard isActive else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isActive = false
    }
}
