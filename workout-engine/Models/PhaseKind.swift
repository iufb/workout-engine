import Foundation

enum PhaseKind: String, Codable, CaseIterable, Sendable {
    case prepare
    case work
    case rest

    var displayName: String {
        switch self {
        case .prepare: String(localized: "Подготовка")
        case .work: String(localized: "Работа")
        case .rest: String(localized: "Отдых")
        }
    }
}
