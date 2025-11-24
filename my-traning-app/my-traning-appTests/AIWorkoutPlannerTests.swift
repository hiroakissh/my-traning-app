import XCTest
@testable import my_traning_app

// テスト専用のモッククライアント
class MockFoundationModelClientForTest: FoundationModelClientProtocol {
    var planResponse = "Test Plan"
    var suggestionResponse = "Test Suggestion"
    var errorToThrow: Error?

    func generatePlan(prompt: String) async throws -> String {
        if let errorToThrow {
            throw errorToThrow
        }
        return planResponse
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {
        if let errorToThrow {
            throw errorToThrow
        }
        return suggestionResponse
    }
}

@MainActor
final class AIWorkoutPlannerTests: XCTestCase {

    var planner: AIWorkoutPlanner!
    var mockClient: MockFoundationModelClientForTest!
    let dummyProfile = UserProfile(age: 30, gender: "男性", height: 175, weight: 70)

    override func setUp() {
        super.setUp()
        mockClient = MockFoundationModelClientForTest()
        planner = AIWorkoutPlanner(foundationModelClient: mockClient)
    }

    override func tearDown() {
        planner = nil
        mockClient = nil
        super.tearDown()
    }

    // MARK: - createPlan Tests

    func test_createPlan_success() async {
        // Given
        let expectedPlan = "Test Plan"
        mockClient.planResponse = expectedPlan

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertFalse(planner.isLoading, "isLoading should be false after completion")
        XCTAssertNil(planner.errorMessage, "errorMessage should be nil on success")
        XCTAssertEqual(planner.generatedPlan, expectedPlan, "generatedPlan should match the mock response")
    }

    func test_createPlan_failure() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.generationFailed(NSError(domain: "TestError", code: 1, userInfo: nil))

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertFalse(planner.isLoading, "isLoading should be false after completion")
        XCTAssertNotNil(planner.errorMessage, "errorMessage should not be nil on failure")
        XCTAssertTrue(planner.generatedPlan.isEmpty, "generatedPlan should be empty on failure")
    }

    func test_createPlan_unavailableUnknownReasonIncludesDetails() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.unavailable(.unknown(reason: "Maintenance"))

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertEqual(planner.errorMessage, "AIモデルが現在利用できません。時間を置いて再度お試しください。（詳細: Maintenance)")
        XCTAssertTrue(planner.generatedPlan.isEmpty)
    }

    func test_createPlan_unexpectedNSErrorShowsFallbackMessage() async {
        // Given
        mockClient.errorToThrow = NSError(domain: "Test", code: 404, userInfo: nil)

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertEqual(planner.errorMessage, "想定外のエラーが発生しました。（コード: 404)")
        XCTAssertTrue(planner.generatedPlan.isEmpty)
    }

    // MARK: - suggestTodayWorkout Tests

    func test_suggestTodayWorkout_success() async {
        // Given
        let expectedSuggestion = "Test Suggestion"
        mockClient.suggestionResponse = expectedSuggestion

        // When
        await planner.suggestTodayWorkout(prompt: "Test Prompt")

        // Then
        XCTAssertFalse(planner.isLoading, "isLoading should be false after completion")
        XCTAssertNil(planner.errorMessage, "errorMessage should be nil on success")
        XCTAssertEqual(planner.todaySuggestion, expectedSuggestion, "todaySuggestion should match the mock response")
    }

    func test_suggestTodayWorkout_failure() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.generationFailed(NSError(domain: "TestError", code: 2, userInfo: nil))

        // When
        await planner.suggestTodayWorkout(prompt: "Test Prompt")

        // Then
        XCTAssertFalse(planner.isLoading, "isLoading should be false after completion")
        XCTAssertNotNil(planner.errorMessage, "errorMessage should not be nil on failure")
        XCTAssertTrue(planner.todaySuggestion.isEmpty, "todaySuggestion should be empty on failure")
    }

    func test_suggestTodayWorkout_deviceNotEligibleErrorShowsLocalizedMessage() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.unavailable(.deviceNotEligible)

        // When
        await planner.suggestTodayWorkout(prompt: "Test Prompt")

        // Then
        XCTAssertEqual(planner.errorMessage, "このデバイスではApple Intelligenceを利用できません。")
        XCTAssertTrue(planner.todaySuggestion.isEmpty)
    }

    func test_createPlan_appleIntelligenceNotEnabledShowsGuidance() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.unavailable(.appleIntelligenceNotEnabled)

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertEqual(planner.errorMessage, "設定アプリからApple Intelligenceを有効にして再度お試しください。")
        XCTAssertTrue(planner.generatedPlan.isEmpty)
    }

    func test_createPlan_modelNotReadyShowsRetryMessage() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.unavailable(.modelNotReady)

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertEqual(planner.errorMessage, "Apple Intelligenceの準備中です。ダウンロード完了後にもう一度お試しください。")
        XCTAssertTrue(planner.generatedPlan.isEmpty)
    }

    func test_suggestTodayWorkout_sessionUnavailableShowsRecoveryMessage() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.sessionUnavailable

        // When
        await planner.suggestTodayWorkout(prompt: "Test Prompt")

        // Then
        XCTAssertEqual(planner.errorMessage, "AIセッションを初期化できませんでした。デバイスの状態を確認してから再試行してください。")
    }
}
