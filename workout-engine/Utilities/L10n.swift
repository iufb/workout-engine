import Foundation

/// Resolves copy from `Localizable.xcstrings` using the in-app language preference.
enum L10n {
    static func t(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: AppSettings.shared.contentLocale)
    }
}
