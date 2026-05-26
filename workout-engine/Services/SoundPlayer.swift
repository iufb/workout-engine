import AVFoundation
import AudioToolbox

enum WorkoutSound: String {
    case phaseStart = "phase_start"
    case workStart = "work_start"
    case restStart = "rest_start"
    case workoutComplete = "workout_complete"
}

final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [WorkoutSound: AVAudioPlayer] = [:]
    private var keepAlivePlayer: AVAudioPlayer?

    private init() {
        preload()
    }

    private func preload() {
        for sound in [WorkoutSound.phaseStart, .workStart, .restStart, .workoutComplete] {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
                players[sound] = try? AVAudioPlayer(contentsOf: url)
                players[sound]?.prepareToPlay()
            }
        }
        if let url = Bundle.main.url(forResource: "silence_loop", withExtension: "wav") {
            keepAlivePlayer = try? AVAudioPlayer(contentsOf: url)
            keepAlivePlayer?.numberOfLoops = -1
            keepAlivePlayer?.volume = 0.01
            keepAlivePlayer?.prepareToPlay()
        }
    }

    func startKeepAlive() {
        guard AppSettings.shared.soundsEnabled else { return }
        keepAlivePlayer?.play()
    }

    func stopKeepAlive() {
        keepAlivePlayer?.stop()
        keepAlivePlayer?.currentTime = 0
    }

    func playPhaseTransition(to kind: PhaseKind) {
        guard AppSettings.shared.shouldPlaySound(for: kind) else { return }
        let sound: WorkoutSound
        switch kind {
        case .prepare:
            sound = .phaseStart
        case .work:
            sound = .workStart
        case .rest:
            sound = .restStart
        }
        play(sound)
    }

    func playWorkoutComplete() {
        guard AppSettings.shared.shouldPlaySound(for: nil) else { return }
        play(.workoutComplete)
    }

    private func play(_ sound: WorkoutSound) {
        if let player = players[sound] {
            player.currentTime = 0
            player.play()
            return
        }
        // Fallback system sounds if bundled assets are missing.
        let systemSoundID: SystemSoundID
        switch sound {
        case .phaseStart: systemSoundID = 1057
        case .workStart: systemSoundID = 1013
        case .restStart: systemSoundID = 1052
        case .workoutComplete: systemSoundID = 1025
        }
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
