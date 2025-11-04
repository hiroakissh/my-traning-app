import XCTest
import FoundationModels
@testable import my_traning_app

final class FoundationModelAvailabilityStatusTests: XCTestCase {

    func test_initFromAvailability_deviceNotEligible() {
        let status = FoundationModelAvailabilityStatus(from: .unavailable(.deviceNotEligible))
        XCTAssertEqual(status, .deviceNotEligible)
    }

    func test_initFromAvailability_appleIntelligenceNotEnabled() {
        let status = FoundationModelAvailabilityStatus(from: .unavailable(.appleIntelligenceNotEnabled))
        XCTAssertEqual(status, .appleIntelligenceNotEnabled)
    }

    func test_initFromAvailability_modelNotReady() {
        let status = FoundationModelAvailabilityStatus(from: .unavailable(.modelNotReady))
        XCTAssertEqual(status, .modelNotReady)
    }

    func test_initFromAvailability_available() {
        let status = FoundationModelAvailabilityStatus(from: .available)
        XCTAssertEqual(status, .available)
    }

    func test_guidanceMessage_forEachAvailability() {
        XCTAssertEqual(FoundationModelAvailabilityStatus.available.guidanceMessage, "")
        XCTAssertEqual(FoundationModelAvailabilityStatus.deviceNotEligible.guidanceMessage, "このデバイスではApple Intelligenceを利用できません。")
        XCTAssertEqual(FoundationModelAvailabilityStatus.appleIntelligenceNotEnabled.guidanceMessage, "設定アプリからApple Intelligenceを有効にして再度お試しください。")
        XCTAssertEqual(FoundationModelAvailabilityStatus.modelNotReady.guidanceMessage, "Apple Intelligenceの準備中です。ダウンロード完了後にもう一度お試しください。")
    }

    func test_guidanceMessage_unknownReasonIncludesDetails() {
        let detailed = FoundationModelAvailabilityStatus.unknown(reason: "networkError")
        XCTAssertEqual(detailed.guidanceMessage, "AIモデルが現在利用できません。時間を置いて再度お試しください。（詳細: networkError)")

        let generic = FoundationModelAvailabilityStatus.unknown(reason: "")
        XCTAssertEqual(generic.guidanceMessage, "AIモデルが現在利用できません。時間を置いて再度お試しください。")
    }
}
