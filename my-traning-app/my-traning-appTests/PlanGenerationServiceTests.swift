import XCTest
@testable import my_traning_app

private final class SequencedFoundationModelClient: FoundationModelClientProtocol {
    var dailyResponses: [DailyRecommendationOutput]
    var dailyPrompts: [String] = []

    init(dailyResponses: [DailyRecommendationOutput]) {
        self.dailyResponses = dailyResponses
    }

    func generatePlan(prompt: String) async throws -> String {
        "unused"
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {
        "unused"
    }

    func generateDailyRecommendation(prompt: String) async throws -> DailyRecommendationOutput {
        dailyPrompts.append(prompt)
        guard !dailyResponses.isEmpty else {
            throw FoundationModelError.sessionUnavailable
        }
        return dailyResponses.removeFirst()
    }
}

private final class ThrowingPlanGenerationService: PlanGenerationService {
    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?
    ) async throws -> DailyRecommendation {
        throw FoundationModelError.sessionUnavailable
    }
}

private final class StaticPlanGenerationService: PlanGenerationService {
    let recommendation: DailyRecommendation

    init(recommendation: DailyRecommendation) {
        self.recommendation = recommendation
    }

    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?
    ) async throws -> DailyRecommendation {
        recommendation
    }
}

final class PlanGenerationServiceTests: XCTestCase {
    func test_validatorRejectsWorkoutWithoutExercises() {
        let recommendation = makeRecommendation(
            recommendationType: .lightWorkout,
            plannedExercises: []
        )

        XCTAssertThrowsError(try DailyRecommendationValidator.validate(recommendation)) { error in
            XCTAssertEqual(error as? DailyRecommendationValidationError, .workoutPlanHasNoExercises)
        }
    }

    func test_validatorRejectsRestPlanWithExercises() {
        let recommendation = makeRecommendation(
            readinessLevel: .rest,
            recommendationType: .rest,
            plannedExercises: [
                PlannedExercise(order: 1, name: "ベンチプレス", detail: "高負荷", targetSets: 3, targetReps: 8, estimatedMinutes: 20, category: .strength)
            ]
        )

        XCTAssertThrowsError(try DailyRecommendationValidator.validate(recommendation)) { error in
            XCTAssertEqual(error as? DailyRecommendationValidationError, .restPlanHasWorkoutExercises)
        }
    }

    func test_aiServiceRetriesOnceWithValidationReason() async throws {
        let invalid = DailyRecommendationOutput(
            readinessLevel: .easy,
            recommendationType: .lightWorkout,
            title: "Invalid",
            summary: "Invalid",
            reasons: ["Reason 1", "Reason 2"],
            exercises: [],
            alternatives: [
                AlternativePlanOutput(title: "Short", description: "Short", estimatedMinutes: 10, intensity: 2),
                AlternativePlanOutput(title: "Rest", description: "Rest", estimatedMinutes: 0, intensity: 1)
            ],
            recoveryAdvice: ["Advice"]
        )
        let valid = DailyRecommendationOutput(
            readinessLevel: .easy,
            recommendationType: .lightWorkout,
            title: "Valid",
            summary: "Valid Summary",
            reasons: ["Reason 1", "Reason 2"],
            exercises: [
                PlannedExerciseOutput(name: "自重スクワット", detail: "軽く動く", targetSets: 2, targetReps: 10, weightDescription: nil, estimatedMinutes: 8, category: .strength)
            ],
            alternatives: [
                AlternativePlanOutput(title: "短縮", description: "1セットだけ", estimatedMinutes: 5, intensity: 2),
                AlternativePlanOutput(title: "休養", description: "休む", estimatedMinutes: 0, intensity: 1)
            ],
            recoveryAdvice: ["余力を残す"]
        )
        let client = SequencedFoundationModelClient(dailyResponses: [invalid, valid])
        let service = AIPlanGenerationService(foundationModelClient: client)

        let recommendation = try await service.generateDailyRecommendation(
            checkIn: makeCheckIn(),
            goal: nil,
            recentLogs: [],
            currentPlan: nil
        )

        XCTAssertEqual(recommendation.title, "Valid")
        XCTAssertEqual(client.dailyPrompts.count, 2)
        XCTAssertTrue(client.dailyPrompts[1].contains("前回の出力は invalid"))
        XCTAssertTrue(client.dailyPrompts[1].contains("plannedExercises が空"))
    }

    func test_coordinatorFallsBackToRuleBasedRecommendation() async throws {
        let fallback = DailyRecommendationGenerator().generate(checkIn: makeCheckIn())
        let coordinator = PlanGenerationCoordinator(
            aiService: ThrowingPlanGenerationService(),
            fallbackService: StaticPlanGenerationService(recommendation: fallback)
        )

        let recommendation = try await coordinator.generateDailyRecommendation(
            checkIn: makeCheckIn(),
            goal: nil,
            recentLogs: [],
            currentPlan: nil
        )

        XCTAssertEqual(recommendation.generationSource, .ruleBased)
        XCTAssertEqual(recommendation.recommendationType, .rest)
        XCTAssertNotNil(recommendation.generationNotice)
    }

    private func makeCheckIn() -> DailyCheckIn {
        DailyCheckIn(
            sleepQuality: .poor,
            fatigueLevel: .high,
            moodLevel: .normal,
            sorenessLevel: .strong,
            availableMinutes: 30,
            motivationLevel: .normal
        )
    }

    private func makeRecommendation(
        readinessLevel: ReadinessLevel = .easy,
        recommendationType: RecommendationType = .lightWorkout,
        plannedExercises: [PlannedExercise]
    ) -> DailyRecommendation {
        DailyRecommendation(
            readinessLevel: readinessLevel,
            recommendationType: recommendationType,
            title: "Test",
            summary: "Summary",
            reasons: ["Reason 1", "Reason 2"],
            plannedExercises: plannedExercises,
            alternatives: [
                AlternativePlan(title: "短縮", description: "短く実行", estimatedMinutes: 10, intensity: 2),
                AlternativePlan(title: "休養", description: "休む", estimatedMinutes: 0, intensity: 1)
            ],
            recoveryAdvice: ["Advice"]
        )
    }
}
