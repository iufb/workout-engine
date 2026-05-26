import XCTest
@testable import workout_engine

final class DurationParsingTests: XCTestCase {
    func testParsePlainSeconds() {
        guard case .success(let value) = DurationParsing.parse("90", kind: .work) else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(value, 90)
    }

    func testParseClockFormat() {
        guard case .success(let value) = DurationParsing.parse("1:30", kind: .work) else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(value, 90)

        guard case .success(let rest) = DurationParsing.parse("0:45", kind: .rest) else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(rest, 45)
    }

    func testParsePrepareAllowsZero() {
        guard case .success(let value) = DurationParsing.parse("0", kind: .prepare) else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(value, 0)
    }

    func testParseWorkRejectsZero() {
        guard case .failure = DurationParsing.parse("0", kind: .work) else {
            return XCTFail("Expected failure for zero work duration")
        }
    }

    func testParseInvalidFormat() {
        guard case .failure = DurationParsing.parse("abc", kind: .work) else {
            return XCTFail("Expected failure for invalid input")
        }
    }

    func testFormatDisplay() {
        XCTAssertEqual(DurationParsing.format(seconds: 45), "45")
        XCTAssertEqual(DurationParsing.format(seconds: 90), "1:30")
    }
}
