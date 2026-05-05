import XCTest
@testable import my_traning_app

final class WorkoutSessionLifecycleServiceTests: XCTestCase {
    func test_makeSessionBuildsPlannedAndActualSetsFromRecommendation() {
        let recommendation = makeRecommendation()
        let service = WorkoutSessionLifecycleService()

        let session = service.makeSession(from: recommendation, startedAt: Date(timeIntervalSince1970: 1_700_000_000))

        XCTAssertEqual(session.recommendationId, recommendation.id)
        XCTAssertEqual(session.status, .notStarted)
        XCTAssertEqual(session.exercises.count, 1)
        XCTAssertEqual(session.exercises.first?.plannedSets.count, 3)
        XCTAssertEqual(session.exercises.first?.actualSets.count, 3)
        XCTAssertEqual(session.exercises.first?.plannedSets.first?.weight, 60)
        XCTAssertEqual(session.exercises.first?.actualSets.first?.reps, 8)
    }

    func test_makeTrainingLogStoresRecommendationSessionResultAndPlanDelta() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let recommendation = makeRecommendation()
        let service = WorkoutSessionLifecycleService()
        let session = service.makeSession(from: recommendation, startedAt: start)
        let exercise = try XCTUnwrap(session.exercises.first)
        let sets = exercise.actualSets.sorted { $0.order < $1.order }

        sets[0].status = .completed
        sets[0].completedAt = start.addingTimeInterval(60)
        sets[0].rpe = 7
        sets[1].reps = 6
        sets[1].status = .modified
        sets[1].completedAt = start.addingTimeInterval(120)
        sets[1].rpe = 9
        sets[2].status = .skipped
        exercise.status = .inProgress
        session.status = .partiallyCompleted
        session.endedAt = start.addingTimeInterval(900)
        session.userNote = "最後は短縮"

        let log = service.makeTrainingLog(from: session, recommendation: recommendation)

        XCTAssertEqual(log.recommendationId, recommendation.id)
        XCTAssertEqual(log.workoutSessionId, session.id)
        XCTAssertEqual(log.activityResult, .partiallyCompleted)
        XCTAssertEqual(log.exercises.count, 1)
        XCTAssertEqual(log.exercises.first?.sets.count, 2)
        XCTAssertEqual(try XCTUnwrap(log.averageRPE), 8, accuracy: 0.01)
        XCTAssertEqual(log.userNote, "最後は短縮")
        XCTAssertTrue(log.wasPlanned)
        XCTAssertTrue(log.wasShortened)
        XCTAssertTrue(log.hadSkippedItems)
        XCTAssertTrue(log.planDeltaSummary?.contains("スキップ1セット") ?? false)
    }

    func test_makeRestedLogSeparatesRestedFromSkipped() {
        let recommendation = makeRecommendation(recommendationType: .rest, exercises: [])
        let service = WorkoutSessionLifecycleService()

        let log = service.makeRestedLog(from: recommendation, changedToRest: true)

        XCTAssertEqual(log.activityResult, .rested)
        XCTAssertNotEqual(log.activityResult, .skipped)
        XCTAssertEqual(log.exercises.count, 0)
        XCTAssertTrue(log.changedToRest)
        XCTAssertTrue(log.wasPlanned)
    }

    private func makeRecommendation(
        recommendationType: RecommendationType = .lightWorkout,
        exercises: [PlannedExercise]? = nil
    ) -> DailyRecommendation {
        DailyRecommendation(
            readinessLevel: recommendationType == .rest ? .rest : .easy,
            recommendationType: recommendationType,
            title: "上半身ライト",
            summary: "フォーム確認を中心に進めます。",
            reasons: ["疲労を考慮します。", "継続を優先します。"],
            plannedExercises: exercises ?? [
                PlannedExercise(
                    order: 1,
                    name: "ベンチプレス",
                    detail: "重量を追わずフォーム確認",
                    targetSets: 3,
                    targetReps: 8,
                    weightDescription: "60kg",
                    estimatedMinutes: 12,
                    category: .strength
                )
            ],
            alternatives: [
                AlternativePlan(title: "短縮", description: "1種目だけ", estimatedMinutes: 10, intensity: 2),
                AlternativePlan(title: "休養", description: "休む", estimatedMinutes: 0, intensity: 1)
            ],
            recoveryAdvice: ["余力を残します。"]
        )
    }
}
