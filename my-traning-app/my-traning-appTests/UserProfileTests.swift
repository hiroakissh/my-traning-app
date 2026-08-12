import XCTest
@testable import my_traning_app

final class UserProfileTests: XCTestCase {
    func testIncompleteProfileIsRejected() {
        let profile = UserProfile(age: 30, gender: "男性", height: 175, weight: nil)

        XCTAssertFalse(profile.isComplete)
        XCTAssertEqual(profile.validationMessage, "体重を25〜300kgで入力してください。")
    }

    func testProfileStoreRoundTripsValues() throws {
        let suiteName = "UserProfileTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let profile = UserProfile(age: 32, gender: "女性", height: 162, weight: 54)
        try UserProfileStore.save(profile, to: defaults)

        XCTAssertEqual(UserProfileStore.load(from: defaults), profile)
    }
}
