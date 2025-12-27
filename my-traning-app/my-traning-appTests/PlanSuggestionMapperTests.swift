import XCTest
@testable import my_traning_app

final class PlanSuggestionMapperTests: XCTestCase {

    func test_map_createsSuggestionsFromHeadings() {
        let response = """
        ## 新しいトレーニングプラン

        ### 長期プラン (3ヶ月)
        - ベンチプレス 100kgを目指す

        ### 中期プラン (1ヶ月)
        - 週4回の分割トレーニング

        ### 短期プラン (今週)
        - 月: 胸の日
        """

        let result = PlanSuggestionMapper.map(from: response, prompt: "goal: bench press 100kg")

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].horizon, .longTerm)
        XCTAssertEqual(result[0].title, "長期プラン (3ヶ月)")
        XCTAssertEqual(result[1].horizon, .midTerm)
        XCTAssertEqual(result[2].horizon, .shortTerm)
        XCTAssertTrue(result.allSatisfy { !$0.summary.isEmpty })
    }

    func test_map_withoutHeadingsReturnsFallback() {
        let response = "全身をバランスよく鍛える週3回プラン"

        let result = PlanSuggestionMapper.map(from: response, prompt: "prompt")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.horizon, .general)
        XCTAssertEqual(result.first?.detail, response)
    }
}
