import AVFoundation
import AudioToolbox
import os

enum WorkoutSound: String, CaseIterable {
    case phaseStart = "phase_start"
    case workStart = "work_start"
    case restStart = "rest_start"
    case workoutComplete = "workout_complete"
    case phaseStartLoud = "phase_start_loud"
    case phaseCountdownSoft = "phase_countdown_soft"
}

final class SoundPlayer {
    static let shared = SoundPlayer()

    private static let soundsSubdirectory = "Sounds"
    private static let phaseStartLoudVolume: Float = 1.0
    private static let countdownSoftVolume: Float = 0.45
    private static let logger = Logger(subsystem: "iufb.workout-engine", category: "SoundPlayer")

    private var players: [WorkoutSound: AVAudioPlayer] = [:]
    private var keepAlivePlayer: AVAudioPlayer?
    private var isSessionAudioActive = false
    private var keepAliveResumeTask: Task<Void, Never>?

    private init() {
        preload()
    }

    /// Call after `AudioSessionManager.activateForWorkout()` so players bind to the active session.
    func prepareForWorkoutSession() {
        if players.isEmpty || keepAlivePlayer == nil {
            preload()
        }
        for player in players.values {
            player.prepareToPlay()
        }
        keepAlivePlayer?.prepareToPlay()
    }

    private func preload() {
        players.removeAll()
        for sound in WorkoutSound.allCases {
            guard let url = soundURL(named: sound.rawValue) else {
                Self.logger.error("Missing sound resource: \(sound.rawValue).wav")
                continue
            }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                players[sound] = player
                player.prepareToPlay()
            }
        }

        if let url = soundURL(named: "silence_loop") {
            keepAlivePlayer = try? AVAudioPlayer(contentsOf: url)
            keepAlivePlayer?.numberOfLoops = -1
            keepAlivePlayer?.volume = 0.01
            keepAlivePlayer?.prepareToPlay()
        } else {
            #if DEBUG
            assertionFailure("silence_loop.wav missing from app bundle — background workout timer will not run")
            #endif
            Self.logger.error("silence_loop.wav missing from app bundle")
        }
    }

    private func soundURL(named name: String) -> URL? {
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: "wav",
            subdirectory: Self.soundsSubdirectory
        ) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: "wav")
    }

    /// Keeps the app eligible for background execution via `UIBackgroundModes = audio`.
    /// Independent of workout sound effect settings.
    func startSessionAudio() {
        guard !isSessionAudioActive else { return }
        guard let keepAlivePlayer else {
            Self.logger.error("Cannot start session audio: keep-alive player unavailable")
            return
        }
        keepAlivePlayer.play()
        isSessionAudioActive = true
    }

    func stopSessionAudio() {
        keepAliveResumeTask?.cancel()
        keepAliveResumeTask = nil
        guard isSessionAudioActive else { return }
        keepAlivePlayer?.stop()
        keepAlivePlayer?.currentTime = 0
        isSessionAudioActive = false
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
        pauseKeepAliveForEffect()

        if let player = players[sound] {
            player.currentTime = 0
            player.volume = volume
            player.play()
            scheduleKeepAliveResume(after: max(player.duration, 0.15) + 0.05)
            return
        }

        Self.logger.warning("Falling back to system sound for \(sound.rawValue)")
        playSystemFallback(for: sound)
        scheduleKeepAliveResume(after: 0.35)
    }

    private func pauseKeepAliveForEffect() {
        keepAliveResumeTask?.cancel()
        guard isSessionAudioActive else { return }
        keepAlivePlayer?.pause()
    }

    private func scheduleKeepAliveResume(after delay: TimeInterval) {
        guard isSessionAudioActive, let keepAlivePlayer else { return }
        keepAliveResumeTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, isSessionAudioActive else { return }
            if !keepAlivePlayer.isPlaying {
                keepAlivePlayer.play()
            }
        }
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
