import XCTest
@testable import workout_engine

final class AppSettingsTests: XCTestCase {
    private let key = "lastUsedPresetID"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
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
}
