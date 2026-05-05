import XCTest
@testable import my_traning_app

final class DailyRecommendationGeneratorTests: XCTestCase {

    func test_decideReadiness_returnsRestForHighRiskCheckIn() {
        let checkIn = DailyCheckIn(
            sleepQuality: .poor,
            fatigueLevel: .high,
            moodLevel: .low,
            sorenessLevel: .strong,
            availableMinutes: 10,
            motivationLevel: .low
        )

        let generator = DailyRecommendationGenerator()

        XCTAssertEqual(generator.decideReadiness(checkIn: checkIn), .rest)
    }

    func test_decideReadiness_returnsEasyForMediumRiskCheckIn() {
        let checkIn = DailyCheckIn(
            sleepQuality: .poor,
            fatigueLevel: .normal,
            moodLevel: .normal,
            sorenessLevel: .mild,
            availableMinutes: 10,
            motivationLevel: .normal
        )

        let generator = DailyRecommendationGenerator()

        XCTAssertEqual(generator.decideReadiness(checkIn: checkIn), .easy)
    }

    func test_generateIncludesRestAsValidPlan() {
        let checkIn = DailyCheckIn(
            sleepQuality: .poor,
            fatigueLevel: .high,
            moodLevel: .low,
            sorenessLevel: .strong,
            availableMinutes: 10,
            motivationLevel: .low
        )
        let goal = UserGoal(goalType: .habit, title: "運動習慣を戻す")
        let generator = DailyRecommendationGenerator()

        let output = generator.generateOutput(checkIn: checkIn, goal: goal)

        XCTAssertEqual(output.readinessLevel, .rest)
        XCTAssertEqual(output.recommendationType, .rest)
        XCTAssertFalse(output.reasons.isEmpty)
        XCTAssertTrue(output.alternatives.contains { $0.estimatedMinutes == 0 })
        XCTAssertTrue(output.recoveryAdvice.contains { $0.contains("休む") || $0.contains("回復") })
    }

    func test_goalTypeChangesRecommendationShape() {
        let checkIn = DailyCheckIn(
            sleepQuality: .good,
            fatigueLevel: .low,
            moodLevel: .high,
            sorenessLevel: .none,
            availableMinutes: 60,
            motivationLevel: .high
        )
        let generator = DailyRecommendationGenerator()

        let strength = generator.generateOutput(checkIn: checkIn, goal: UserGoal(goalType: .strength, title: "筋力アップ"))
        let mentalRecovery = generator.generateOutput(checkIn: checkIn, goal: UserGoal(goalType: .mentalRecovery, title: "気分を整える"))

        XCTAssertNotEqual(strength.title, mentalRecovery.title)
        XCTAssertTrue(strength.exercises.contains { $0.category == .strength })
        XCTAssertTrue(mentalRecovery.exercises.contains { $0.category == .cardio || $0.category == .mobility })
    }
}
