import Foundation

enum TimeFormatting {
    static func countdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }

    static func durationLabel(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0, seconds > 0 {
            return L10n.t("\(minutes) мин \(seconds) с")
        }
        if minutes > 0 {
            return L10n.t("\(minutes) мин")
        }
        return L10n.t("\(seconds) с")
    }
}
