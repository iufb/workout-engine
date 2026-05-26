import SwiftUI
import XCTest
@testable import workout_engine

final class AppSettingsTests: XCTestCase {
    private let key = "lastUsedPresetID"
    private let appearanceKey = "appearance"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: appearanceKey)
        super.tearDown()
    }

    func testLastUsedPresetIDPersists() {
        let id = UUID()
        AppSettings.shared.lastUsedPresetID = id
        XCTAssertEqual(AppSettings.shared.lastUsedPresetID, id)
        XCTAssertEqual(UserDefaults.standard.string(forKey: key), id.uuidString)
    }

    func testLastUsedPresetIDClears() {
        AppSettings.shared.lastUsedPresetID = UUID()
        AppSettings.shared.lastUsedPresetID = nil
        XCTAssertNil(AppSettings.shared.lastUsedPresetID)
        XCTAssertNil(UserDefaults.standard.string(forKey: key))
    }

    func testContentLocaleForSystemLanguageCode() {
        XCTAssertEqual(
            AppLanguage.contentLocale(forSystemLanguageCode: "ru").identifier,
            "ru"
        )
        XCTAssertEqual(
            AppLanguage.contentLocale(forSystemLanguageCode: "en").identifier,
            "en"
        )
        XCTAssertEqual(
            AppLanguage.contentLocale(forSystemLanguageCode: "kk").identifier,
            "en"
        )
        XCTAssertEqual(
            AppLanguage.contentLocale(forSystemLanguageCode: nil).identifier,
            "en"
        )
    }

    func testContentLocaleUsesRuOrEnIdentifier() {
        let ru = AppLanguage.contentLocale(forSystemLanguageCode: "ru")
        let en = AppLanguage.contentLocale(forSystemLanguageCode: "de")
        XCTAssertTrue(ru.identifier.hasPrefix("ru"))
        XCTAssertTrue(en.identifier.hasPrefix("en"))
    }

    func testAppearanceResolvedColorScheme() {
        XCTAssertNil(AppAppearance.system.resolvedColorScheme)
        XCTAssertEqual(AppAppearance.light.resolvedColorScheme, .light)
        XCTAssertEqual(AppAppearance.dark.resolvedColorScheme, .dark)
    }

    func testAppearancePersists() {
        let settings = AppSettings.shared
        let previous = settings.appearance
        defer {
            settings.appearance = previous
            if previous == .system {
                UserDefaults.standard.removeObject(forKey: appearanceKey)
            }
        }

        settings.appearance = .dark
        XCTAssertEqual(settings.appearance, .dark)
        XCTAssertEqual(UserDefaults.standard.string(forKey: appearanceKey), AppAppearance.dark.rawValue)
        XCTAssertEqual(settings.resolvedColorScheme, .dark)
    }
}
