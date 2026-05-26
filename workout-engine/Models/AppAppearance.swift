import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var resolvedColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system:
            return L10n.t("Системная")
        case .light:
            return L10n.t("Светлая")
        case .dark:
            return L10n.t("Тёмная")
        }
    }
}
