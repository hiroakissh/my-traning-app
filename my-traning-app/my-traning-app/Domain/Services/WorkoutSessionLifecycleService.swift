import Foundation

struct WorkoutSessionLifecycleService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makeSession(
        from recommendation: DailyRecommendation,
        goalId: UUID? = nil,
        startedAt: Date = Date()
    ) -> WorkoutSession {
        let exercises = recommendation.plannedExercises
            .sorted { $0.order < $1.order }
            .map { makeSessionExercise(from: $0) }

        return WorkoutSession(
            recommendationId: recommendation.id,
            goalId: goalId,
            startedAt: startedAt,
            status: .notStarted,
            exercises: exercises
        )
    }

    func makeTrainingLog(
        from session: WorkoutSession,
        recommendation: DailyRecommendation?,
        endedAt: Date = Date()
    ) -> TrainingLog {
        let endTime = session.endedAt ?? endedAt
        let duration = max(Int(endTime.timeIntervalSince(session.startedAt)), 0)
        let result = activityResult(for: session, recommendation: recommendation)
        let executedExercises = session.exercises
            .sorted { $0.order < $1.order }
            .compactMap(makeTrainingExercise)
        let rpeValues = session.exercises
            .flatMap(\.actualSets)
            .compactMap(\.rpe)
        let averageRPE = rpeValues.isEmpty ? nil : Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
        let delta = makePlanDeltaSummary(for: session)

        return TrainingLog(
            recommendationId: session.recommendationId,
            workoutSessionId: session.id,
            goalId: session.goalId,
            date: calendar.startOfDay(for: session.startedAt),
            startedAt: session.startedAt,
            endedAt: endTime,
            sessionDurationSec: duration,
            purpose: recommendation?.recommendationType.defaultPurpose ?? .other,
            source: .timer,
            activityResult: result,
            exercises: executedExercises,
            averageRPE: averageRPE,
            note: session.userNote,
            wasPlanned: session.recommendationId != nil,
            wasShortened: delta.wasShortened,
            hadSkippedItems: delta.skippedCount > 0,
            changedToRest: false,
            planDeltaSummary: delta.summary
        )
    }

    func makeRestedLog(
        from recommendation: DailyRecommendation,
        goalId: UUID? = nil,
        note: String? = nil,
        date: Date = Date(),
        changedToRest: Bool = false
    ) -> TrainingLog {
        TrainingLog(
            recommendationId: recommendation.id,
            goalId: goalId,
            date: calendar.startOfDay(for: date),
            startedAt: nil,
            endedAt: nil,
            sessionDurationSec: 0,
            purpose: .refresh,
            source: .manual,
            activityResult: .rested,
            exercises: [],
            note: note,
            wasPlanned: true,
            wasShortened: false,
            hadSkippedItems: false,
            changedToRest: changedToRest,
            planDeltaSummary: changedToRest ? "トレーニング提案から計画的な休養に変更" : "計画的に休養として記録"
        )
    }

    private func makeSessionExercise(from exercise: PlannedExercise) -> WorkoutSessionExercise {
        let plannedSets = makePlannedSets(from: exercise)
        let actualSets = plannedSets.map {
            ActualSet(
                plannedSetId: $0.id,
                order: $0.order,
                weight: $0.weight,
                reps: $0.reps,
                durationSeconds: $0.durationSeconds,
                distanceMeters: $0.distanceMeters,
                status: .planned
            )
        }

        return WorkoutSessionExercise(
            plannedExerciseId: exercise.id,
            name: exercise.name,
            order: exercise.order,
            plannedSets: plannedSets,
            actualSets: actualSets,
            status: .notStarted,
            category: exercise.category
        )
    }

    private func makePlannedSets(from exercise: PlannedExercise) -> [PlannedSet] {
        let setCount = max(exercise.targetSets ?? 1, 1)
        let parsedWeight = parseWeight(from: exercise.weightDescription)
        let durationSeconds: Int? = exercise.targetSets == nil && exercise.estimatedMinutes > 0
            ? exercise.estimatedMinutes * 60
            : nil

        return (1...setCount).map { order in
            PlannedSet(
                order: order,
                weight: parsedWeight,
                reps: exercise.targetReps,
                durationSeconds: durationSeconds,
                distanceMeters: nil
            )
        }
    }

    private func makeTrainingExercise(from exercise: WorkoutSessionExercise) -> TrainingExercise? {
        let executedSets = exercise.actualSets
            .sorted { $0.order < $1.order }
            .filter { $0.status.isExecuted }
            .map {
                TrainingSet(
                    order: $0.order,
                    weightKg: $0.weight,
                    reps: $0.reps,
                    durationSec: $0.durationSeconds,
                    rpe: $0.rpe.map(Double.init),
                    isBodyweight: $0.weight == nil
                )
            }

        guard !executedSets.isEmpty else { return nil }

        return TrainingExercise(
            name: exercise.name,
            bodyPart: .other,
            category: exercise.category,
            sets: executedSets
        )
    }

    private func activityResult(
        for session: WorkoutSession,
        recommendation: DailyRecommendation?
    ) -> ActivityResult {
        if recommendation?.recommendationType == .recovery {
            return .recoveryCompleted
        }

        switch session.status {
        case .completed:
            return .completed
        case .partiallyCompleted:
            return .partiallyCompleted
        case .cancelled, .notStarted:
            return .skipped
        case .inProgress:
            return hasExecutedSet(session) ? .partiallyCompleted : .skipped
        }
    }

    private func hasExecutedSet(_ session: WorkoutSession) -> Bool {
        session.exercises.flatMap(\.actualSets).contains { $0.status.isExecuted }
    }

    private func makePlanDeltaSummary(for session: WorkoutSession) -> (summary: String, wasShortened: Bool, skippedCount: Int) {
        let plannedCount = session.exercises.flatMap(\.plannedSets).count
        let actualSets = session.exercises.flatMap(\.actualSets)
        let completedCount = actualSets.filter { $0.status == .completed || $0.status == .modified }.count
        let modifiedCount = actualSets.filter { $0.status == .modified }.count
        let skippedCount = actualSets.filter { $0.status == .skipped }.count
        let summary = "予定\(plannedCount)セット / 完了\(completedCount)セット / 変更\(modifiedCount)セット / スキップ\(skippedCount)セット"
        return (summary, completedCount < plannedCount || skippedCount > 0, skippedCount)
    }

    private func parseWeight(from description: String?) -> Double? {
        guard let description else { return nil }
        let normalized = description
            .replacingOccurrences(of: "kg", with: "")
            .replacingOccurrences(of: "KG", with: "")
            .replacingOccurrences(of: "キロ", with: "")
        let firstNumber = normalized
            .split(whereSeparator: { !$0.isNumber && $0 != "." })
            .first
        return firstNumber.flatMap { Double($0) }
    }
}
