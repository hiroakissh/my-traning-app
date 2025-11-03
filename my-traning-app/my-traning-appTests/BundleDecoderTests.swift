import XCTest
@testable import my_traning_app

final class BundleDecoderTests: XCTestCase {

    func test_decode_missingFileThrowsFileNotFoundError() {
        XCTAssertThrowsError(try Bundle.main.decode("missing.json") as WorkoutData) { error in
            guard case BundleDecodingError.fileNotFound(let fileName) = error else {
                return XCTFail("Expected fileNotFound error but received: \(error)")
            }
            XCTAssertEqual(fileName, "missing.json")
        }
    }

    func test_decode_invalidDataThrowsDecodingFailedError() {
        struct DummyDecodable: Decodable {
            let value: String
        }

        let invalidJSON = Data("[]".utf8)

        XCTAssertThrowsError(try Bundle.decode(DummyDecodable.self, from: invalidJSON, fileName: "dummy.json")) { error in
            guard case BundleDecodingError.decodingFailed(let fileName, _) = error else {
                return XCTFail("Expected decodingFailed error but received: \(error)")
            }
            XCTAssertEqual(fileName, "dummy.json")
        }
    }
}
