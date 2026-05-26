import AVFoundation
import AudioToolbox

enum WorkoutSound: String {
    case phaseStart = "phase_start"
    case workStart = "work_start"
    case restStart = "rest_start"
    case workoutComplete = "workout_complete"
    case phaseStartLoud = "phase_start_loud"
    case phaseCountdownSoft = "phase_countdown_soft"
}

final class SoundPlayer {
    static let shared = SoundPlayer()

    private static let phaseStartLoudVolume: Float = 1.0
    private static let countdownSoftVolume: Float = 0.45

    private var players: [WorkoutSound: AVAudioPlayer] = [:]
    private var keepAlivePlayer: AVAudioPlayer?

    private init() {
        preload()
    }

    private func preload() {
        let sounds: [WorkoutSound] = [
            .phaseStart, .workStart, .restStart, .workoutComplete,
            .phaseStartLoud, .phaseCountdownSoft,
        ]
        for sound in sounds {
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

    /// Loud bell when a new phase begins.
    func playPhaseStartLoud(for kind: PhaseKind) {
        guard AppSettings.shared.shouldPlaySound(for: kind) else { return }
        if players[.phaseStartLoud] != nil {
            play(.phaseStartLoud, volume: Self.phaseStartLoudVolume)
        } else {
            playPhaseTransition(to: kind)
        }
    }

    /// Soft bell on the last 3 seconds of a phase (3, 2, 1).
    func playCountdownSoft(for kind: PhaseKind) {
        guard AppSettings.shared.soundsEnabled,
              AppSettings.shared.soundOnCountdown,
              AppSettings.shared.shouldPlaySound(for: kind) else { return }
        if players[.phaseCountdownSoft] != nil {
            play(.phaseCountdownSoft, volume: Self.countdownSoftVolume)
        } else {
            play(.phaseStart, volume: Self.countdownSoftVolume)
        }
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

    private func play(_ sound: WorkoutSound, volume: Float = 1.0) {
        if let player = players[sound] {
            player.currentTime = 0
            player.volume = volume
            player.play()
            return
        }
        playSystemFallback(for: sound)
    }

    private func playSystemFallback(for sound: WorkoutSound) {
        let systemSoundID: SystemSoundID
        switch sound {
        case .phaseStart, .phaseStartLoud: systemSoundID = 1057
        case .workStart: systemSoundID = 1013
        case .restStart: systemSoundID = 1052
        case .workoutComplete: systemSoundID = 1025
        case .phaseCountdownSoft: systemSoundID = 1103
        }
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
