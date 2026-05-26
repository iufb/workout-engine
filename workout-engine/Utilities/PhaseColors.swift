import SwiftUI

enum PhaseColors {
    static func background(for kind: PhaseKind) -> Color {
        switch kind {
        case .prepare:
            Color(red: 0.95, green: 0.72, blue: 0.2)
        case .work:
            Color(red: 0.18, green: 0.72, blue: 0.38)
        case .rest:
            Color(red: 0.22, green: 0.45, blue: 0.92)
        }
    }

    static func softBackground(for kind: PhaseKind) -> Color {
        background(for: kind).opacity(0.15)
    }

    static func foreground(for kind: PhaseKind) -> Color {
        .white
    }

    static func symbolName(for kind: PhaseKind) -> String {
        switch kind {
        case .prepare:
            "figure.walk"
        case .work:
            "flame.fill"
        case .rest:
            "pause.circle.fill"
        }
    }
}
