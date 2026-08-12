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

    func test_map_ignoresHeadingsAboveH3() {
        let response = """
        # タイトル
        ## 新しいトレーニングプラン
        ### 長期プラン
        - 内容
        """

        let result = PlanSuggestionMapper.map(from: response, prompt: "prompt")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "長期プラン")
    }

    func test_map_createsSuggestionsFromStructuredOutput() {
        let output = PlanSuggestionsOutput(plans: [
            PlanSuggestionOutput(
                title: "今週の作戦",
                summary: "曜日ごとに進める",
                horizon: "shortTerm",
                detail: "Monday: 胸\n休養: 水曜は軽め"
            )
        ])

        let result = PlanSuggestionMapper.map(from: output, prompt: "prompt")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.horizon, .shortTerm)
        XCTAssertEqual(result.first?.title, "今週の作戦")
        XCTAssertEqual(result.first?.summary, "曜日ごとに進める")
        XCTAssertEqual(result.first?.detail, "Monday: 胸\n休養: 水曜は軽め")
    }

    func test_planDisplayContent_parsesMarkdownLikePlanIntoUISections() {
        let detail = """
        * **Monday:** 胸・背中
        * **Wednesday:** 腕・肩
        * **ボリューム:** 各セット3〜5回
        * **負荷:** 1〜2週間ごとに増やす
        * **休養:**
        * **Tuesday:** 軽いストレッチ
        * **RecoveryAdvice:**
        * **筋肉痛:**
        * **Rest:** 軽いウォーキング
        """

        let content = PlanDisplayContent.parse(detail)

        XCTAssertEqual(content.scheduleItems.map(\.day), ["月", "水"])
        XCTAssertEqual(content.scheduleItems.first?.detail, "胸・背中")
        XCTAssertEqual(content.infoItems.map(\.title), ["ボリューム", "負荷"])
        XCTAssertTrue(content.recoveryItems.contains("火: 軽いストレッチ"))
        XCTAssertTrue(content.recoveryItems.contains("休養: 軽いウォーキング"))
        XCTAssertFalse(content.recoveryItems.contains { $0.contains("**") || $0.contains("*") })
    }
}
