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

    /// Large timer / header on solid phase fill.
    static func foreground(for kind: PhaseKind) -> Color {
        .white
    }

    /// Labels placed directly on the bright phase background (toolbar, etc.).
    static func onPhaseBackground(for kind: PhaseKind) -> Color {
        switch kind {
        case .prepare:
            Color(red: 0.2, green: 0.14, blue: 0.02)
        case .work:
            Color(red: 0.04, green: 0.22, blue: 0.1)
        case .rest:
            Color(red: 0.05, green: 0.1, blue: 0.28)
        }
    }

    /// Text on translucent control pills (dark fill → light label).
    static func controlLabel(on kind: PhaseKind) -> Color {
        .white
    }

    /// Fill for primary/secondary control pills — dark on every phase for contrast.
    static func controlFill(for kind: PhaseKind, pressed: Bool) -> Color {
        let base = Color.black.opacity(pressed ? 0.38 : 0.44)
        return base
    }

    static func controlSecondaryFill(for kind: PhaseKind, pressed: Bool) -> Color {
        Color.black.opacity(pressed ? 0.3 : 0.36)
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
