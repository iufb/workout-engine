import Foundation

enum PhaseKind: String, Codable, CaseIterable, Sendable {
    case prepare
    case work
    case rest

    var displayName: String {
        switch self {
        case .prepare: L10n.t("Подготовка")
        case .work: L10n.t("Работа")
        case .rest: L10n.t("Отдых")
        }
    }
}
