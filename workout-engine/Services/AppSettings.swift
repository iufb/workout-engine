import Foundation
import Observation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var soundsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundsEnabled, forKey: Keys.soundsEnabled) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var keepScreenOnDuringWorkout: Bool {
        didSet { UserDefaults.standard.set(keepScreenOnDuringWorkout, forKey: Keys.keepScreenOn) }
    }

    var soundOnPrepare: Bool {
        didSet { UserDefaults.standard.set(soundOnPrepare, forKey: Keys.soundOnPrepare) }
    }

    var soundOnWork: Bool {
        didSet { UserDefaults.standard.set(soundOnWork, forKey: Keys.soundOnWork) }
    }

    var soundOnRest: Bool {
        didSet { UserDefaults.standard.set(soundOnRest, forKey: Keys.soundOnRest) }
    }

    var soundOnFinish: Bool {
        didSet { UserDefaults.standard.set(soundOnFinish, forKey: Keys.soundOnFinish) }
    }

    private enum Keys {
        static let soundsEnabled = "soundsEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let keepScreenOn = "keepScreenOnDuringWorkout"
        static let soundOnPrepare = "soundOnPrepare"
        static let soundOnWork = "soundOnWork"
        static let soundOnRest = "soundOnRest"
        static let soundOnFinish = "soundOnFinish"
    }

    private init() {
        let defaults = UserDefaults.standard
        soundsEnabled = defaults.object(forKey: Keys.soundsEnabled) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        keepScreenOnDuringWorkout = defaults.object(forKey: Keys.keepScreenOn) as? Bool ?? true
        soundOnPrepare = defaults.object(forKey: Keys.soundOnPrepare) as? Bool ?? true
        soundOnWork = defaults.object(forKey: Keys.soundOnWork) as? Bool ?? true
        soundOnRest = defaults.object(forKey: Keys.soundOnRest) as? Bool ?? true
        soundOnFinish = defaults.object(forKey: Keys.soundOnFinish) as? Bool ?? true
    }

    func shouldPlaySound(for kind: PhaseKind?) -> Bool {
        guard soundsEnabled else { return false }
        guard let kind else { return soundOnFinish }
        switch kind {
        case .prepare: return soundOnPrepare
        case .work: return soundOnWork
        case .rest: return soundOnRest
        }
    }
}
