import Foundation
import Observation
import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()

    /// App content language from system locale: ru, or en (fallback).
    var contentLocale: Locale {
        AppLanguage.contentLocale(
            forSystemLanguageCode: Locale.autoupdatingCurrent.language.languageCode?.identifier
        )
    }

    var resolvedLocale: Locale { contentLocale }

    var resolvedLanguageCode: String {
        contentLocale.language.languageCode?.identifier ?? "en"
    }

    var appearance: AppAppearance {
        didSet {
            guard appearance != oldValue else { return }
            UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance)
        }
    }

    var resolvedColorScheme: ColorScheme? {
        appearance.resolvedColorScheme
    }

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

    var soundOnCountdown: Bool {
        didSet { UserDefaults.standard.set(soundOnCountdown, forKey: Keys.soundOnCountdown) }
    }

    var lastUsedPresetID: UUID? {
        didSet {
            if let lastUsedPresetID {
                UserDefaults.standard.set(lastUsedPresetID.uuidString, forKey: Keys.lastUsedPresetID)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastUsedPresetID)
            }
        }
    }

    private enum Keys {
        static let appearance = "appearance"
        static let soundsEnabled = "soundsEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let keepScreenOn = "keepScreenOnDuringWorkout"
        static let soundOnPrepare = "soundOnPrepare"
        static let soundOnWork = "soundOnWork"
        static let soundOnRest = "soundOnRest"
        static let soundOnFinish = "soundOnFinish"
        static let soundOnCountdown = "soundOnCountdown"
        static let lastUsedPresetID = "lastUsedPresetID"
    }

    private init() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "appLanguage")
        if let raw = defaults.string(forKey: Keys.appearance),
           let savedAppearance = AppAppearance(rawValue: raw) {
            appearance = savedAppearance
        } else {
            appearance = .system
        }
        soundsEnabled = defaults.object(forKey: Keys.soundsEnabled) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        keepScreenOnDuringWorkout = defaults.object(forKey: Keys.keepScreenOn) as? Bool ?? true
        soundOnPrepare = defaults.object(forKey: Keys.soundOnPrepare) as? Bool ?? true
        soundOnWork = defaults.object(forKey: Keys.soundOnWork) as? Bool ?? true
        soundOnRest = defaults.object(forKey: Keys.soundOnRest) as? Bool ?? true
        soundOnFinish = defaults.object(forKey: Keys.soundOnFinish) as? Bool ?? true
        soundOnCountdown = defaults.object(forKey: Keys.soundOnCountdown) as? Bool ?? true
        if let idString = defaults.string(forKey: Keys.lastUsedPresetID) {
            lastUsedPresetID = UUID(uuidString: idString)
        } else {
            lastUsedPresetID = nil
        }
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
