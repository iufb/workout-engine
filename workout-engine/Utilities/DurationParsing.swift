import Foundation

enum DurationParsing {
    enum ParseError: Error {
        case empty
        case invalidFormat
        case outOfRange
    }

    static func parse(_ text: String, kind: PhaseKind) -> Result<Int, ParseError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        let seconds: Int?
        if trimmed.contains(":") {
            seconds = parseClockFormat(trimmed)
        } else if let value = Int(trimmed) {
            seconds = value
        } else {
            seconds = nil
        }

        guard let seconds else { return .failure(.invalidFormat) }

        let range = allowedRange(for: kind)
        guard range.contains(seconds) else { return .failure(.outOfRange) }
        return .success(seconds)
    }

    static func format(seconds: Int) -> String {
        let total = max(0, seconds)
        let minutes = total / 60
        let secs = total % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)"
    }

    static func allowedRange(for kind: PhaseKind) -> ClosedRange<Int> {
        kind == .prepare ? 0 ... 3600 : 1 ... 3600
    }

    static func step(for seconds: Int) -> Int {
        seconds >= 60 ? 5 : 1
    }

    private static func parseClockFormat(_ text: String) -> Int? {
        let parts = text.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let secs = Int(parts[1]),
              minutes >= 0, secs >= 0, secs < 60 else {
            return nil
        }
        return minutes * 60 + secs
    }
}
