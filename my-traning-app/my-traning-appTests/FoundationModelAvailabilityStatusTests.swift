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
}
