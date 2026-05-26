import Foundation

enum AppLanguage {
    /// Maps system language to ru or en; unsupported codes fall back to en.
    static func contentLocale(forSystemLanguageCode code: String?) -> Locale {
        code == "ru" ? Locale(identifier: "ru") : Locale(identifier: "en")
    }
}
