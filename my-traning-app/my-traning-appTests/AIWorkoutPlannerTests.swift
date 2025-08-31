import XCTest
@testable import my_traning_app

// テスト専用のモッククライアント
class MockFoundationModelClientForTest: FoundationModelClientProtocol {
    var shouldThrowError = false
    var planResponse = "Test Plan"
    var suggestionResponse = "Test Suggestion"

    func generatePlan(prompt: String) async throws -> String {
        if shouldThrowError {
            throw FoundationModelError.generationFailed(NSError(domain: "TestError", code: 1, userInfo: nil))
        }
        return planResponse
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {
        if shouldThrowError {
            throw FoundationModelError.generationFailed(NSError(domain: "TestError", code: 2, userInfo: nil))
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
        mockClient.shouldThrowError = false
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
        mockClient.shouldThrowError = true

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertFalse(planner.isLoading, "isLoading should be false after completion")
        XCTAssertNotNil(planner.errorMessage, "errorMessage should not be nil on failure")
        XCTAssertTrue(planner.generatedPlan.isEmpty, "generatedPlan should be empty on failure")
    }

    // MARK: - suggestTodayWorkout Tests

    func test_suggestTodayWorkout_success() async {
        // Given
        mockClient.shouldThrowError = false
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
        mockClient.shouldThrowError = true

        // When
        await planner.suggestTodayWorkout(prompt: "Test Prompt")

        // Then
        XCTAssertFalse(planner.isLoading, "isLoading should be false after completion")
        XCTAssertNotNil(planner.errorMessage, "errorMessage should not be nil on failure")
        XCTAssertTrue(planner.todaySuggestion.isEmpty, "todaySuggestion should be empty on failure")
    }
}
