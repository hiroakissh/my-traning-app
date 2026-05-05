import XCTest
@testable import my_traning_app

// テスト専用のモッククライアント
class MockFoundationModelClientForTest: FoundationModelClientProtocol {
    var planResponse = "Test Plan"
    var suggestionResponse = "Test Suggestion"
    var dailyRecommendationResponse = DailyRecommendationOutput(
        readinessLevel: .easy,
        recommendationType: .lightWorkout,
        title: "Test Recommendation",
        summary: "Test Summary",
        reasons: ["Reason 1", "Reason 2", "Reason 3"],
        exercises: [
            PlannedExerciseOutput(
                name: "Test Exercise",
                detail: "Test Detail",
                targetSets: 2,
                targetReps: 8,
                weightDescription: "light",
                estimatedMinutes: 10,
                category: .strength
            )
        ],
        alternatives: [
            AlternativePlanOutput(title: "Short", description: "Short plan", estimatedMinutes: 10, intensity: 2),
            AlternativePlanOutput(title: "Rest", description: "Rest plan", estimatedMinutes: 0, intensity: 1)
        ],
        recoveryAdvice: ["Advice 1", "Advice 2"]
    )
    var errorToThrow: Error?
    var lastPlanPrompt: String?
    var lastSuggestionPrompt: String?
    var lastDailyRecommendationPrompt: String?

    func generatePlan(prompt: String) async throws -> String {
        lastPlanPrompt = prompt
        if let errorToThrow {
            throw errorToThrow
        }
        return planResponse
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {
        lastSuggestionPrompt = prompt
        if let errorToThrow {
            throw errorToThrow
        }
        return suggestionResponse
    }

    func generateDailyRecommendation(prompt: String) async throws -> DailyRecommendationOutput {
        lastDailyRecommendationPrompt = prompt
        if let errorToThrow {
            throw errorToThrow
        }
        return dailyRecommendationResponse
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
        XCTAssertEqual(planner.planSuggestions.count, 1)
        XCTAssertEqual(planner.planSuggestions.first?.detail, expectedPlan)
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
        XCTAssertTrue(planner.planSuggestions.isEmpty, "planSuggestions should be cleared on failure")
    }

    func test_createPlan_unavailableUnknownReasonIncludesDetails() async {
        // Given
        mockClient.errorToThrow = FoundationModelError.unavailable(.unknown(reason: "Maintenance"))

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertEqual(planner.errorMessage, "AIモデルが現在利用できません。時間を置いて再度お試しください。（詳細: Maintenance)")
        XCTAssertTrue(planner.generatedPlan.isEmpty)
        XCTAssertTrue(planner.planSuggestions.isEmpty)
    }

    func test_createPlan_unexpectedNSErrorShowsFallbackMessage() async {
        // Given
        mockClient.errorToThrow = NSError(domain: "Test", code: 404, userInfo: nil)

        // When
        await planner.createPlan(userProfile: dummyProfile, goal: "Test Goal")

        // Then
        XCTAssertEqual(planner.errorMessage, "想定外のエラーが発生しました。（コード: 404)")
        XCTAssertTrue(planner.generatedPlan.isEmpty)
        XCTAssertTrue(planner.planSuggestions.isEmpty)
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

    func test_createPlan_buildsPromptWithUserProfile() async {
        await planner.createPlan(userProfile: dummyProfile, goal: "筋力アップ")

        let prompt = mockClient.lastPlanPrompt ?? ""
        XCTAssertTrue(prompt.contains("年齢: 30歳"))
        XCTAssertTrue(prompt.contains("性別: 男性"))
        XCTAssertTrue(prompt.contains("身長: 175cm"))
        XCTAssertTrue(prompt.contains("体重: 70kg"))
        XCTAssertTrue(prompt.contains("筋力アップ"))
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

    func test_suggestTodayWorkout_includesContextData() async throws {
        // Given
        let log = TrainingLog(
            date: Date(),
            sessionDurationSec: 1200,
            purpose: .hypertrophy,
            source: .manual,
            exercises: [
                TrainingExercise(
                    name: "Bench Press",
                    bodyPart: .chest,
                    sets: [
                        TrainingSet(order: 1, weightKg: 60, reps: 10, isBodyweight: false)
                    ]
                )
            ]
        )

        let snapshot = HealthDataSnapshot(
            start: Date(),
            end: Date(),
            averageHeartRate: 128,
            restingHeartRate: 60,
            activeEnergyBurned: 500,
            basalEnergyBurned: 200,
            distanceWalkingRunning: 5.2,
            stepCount: 7200,
            vo2Max: nil
        )

        let activePlan = ActivePlan(
            horizon: .shortTerm,
            title: "胸の日 強化",
            summary: "ベンチプレスの重量を伸ばす短期プラン",
            detail: "週3回のプッシュメインセッションを実施し、セット数を段階的に増やす",
            sourcePrompt: "テスト"
        )

        let context = AIAssistantContext(
            userQuery: "肩が張っているので軽めにしたい",
            activePlan: activePlan,
            recentLogs: [log],
            healthSnapshot: snapshot,
            dailyGoalKcal: 1650
        )

        // When
        await planner.suggestTodayWorkout(prompt: "肩が張っているので軽めにしたい", context: context)

        // Then
        let prompt = try XCTUnwrap(mockClient.lastSuggestionPrompt)
        XCTAssertTrue(prompt.contains("5.2 km"))
        XCTAssertTrue(prompt.contains("平均心拍数: 128 bpm"))
        XCTAssertTrue(prompt.contains("肩が張っているので軽めにしたい"))
        XCTAssertTrue(prompt.contains("アクティブプラン"))
    }

    func test_generateDailyRecommendation_usesStructuredClient() async throws {
        let checkIn = DailyCheckIn(
            sleepQuality: .poor,
            fatigueLevel: .high,
            moodLevel: .low,
            sorenessLevel: .strong,
            availableMinutes: 10,
            motivationLevel: .low
        )
        let goal = UserGoal(goalType: .strength, title: "ベンチプレス100kg", targetMetric: "100kg", priority: 1)

        await planner.generateDailyRecommendation(checkIn: checkIn, goal: goal, recentLogs: [], activePlan: nil)

        let prompt = try XCTUnwrap(mockClient.lastDailyRecommendationPrompt)
        XCTAssertTrue(prompt.contains("睡眠: 悪い"))
        XCTAssertTrue(prompt.contains("疲労: 重い"))
        XCTAssertTrue(prompt.contains("目標タイプ: 筋力アップ"))
        XCTAssertEqual(planner.dailyRecommendationOutput?.title, "Test Recommendation")
        XCTAssertNil(planner.errorMessage)
    }
}
