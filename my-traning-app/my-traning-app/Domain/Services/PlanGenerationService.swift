import Foundation

typealias WorkoutPlan = ActivePlan

protocol PlanGenerationService {
    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?
    ) async throws -> DailyRecommendation
}

enum DailyRecommendationValidationError: Error, Equatable, LocalizedError {
    case emptyTitle
    case emptySummary
    case noReasons
    case invalidExercise
    case invalidAlternative
    case restPlanHasWorkoutExercises
    case workoutPlanHasNoExercises

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "title が空です"
        case .emptySummary:
            return "summary が空です"
        case .noReasons:
            return "reasons が空です"
        case .invalidExercise:
            return "plannedExercises に不正な種目があります"
        case .invalidAlternative:
            return "alternatives に不正な代替案があります"
        case .restPlanHasWorkoutExercises:
            return "rest なのに plannedExercises が空ではありません"
        case .workoutPlanHasNoExercises:
            return "fullWorkout / lightWorkout なのに plannedExercises が空です"
        }
    }
}

struct DailyRecommendationValidator {
    static func validate(_ recommendation: DailyRecommendation) throws {
        if recommendation.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DailyRecommendationValidationError.emptyTitle
        }

        if recommendation.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DailyRecommendationValidationError.emptySummary
        }

        if recommendation.reasons.isEmpty {
            throw DailyRecommendationValidationError.noReasons
        }

        if recommendation.plannedExercises.contains(where: isInvalidExercise) {
            throw DailyRecommendationValidationError.invalidExercise
        }

        if recommendation.alternatives.contains(where: isInvalidAlternative) || recommendation.alternatives.count < 2 {
            throw DailyRecommendationValidationError.invalidAlternative
        }

        switch recommendation.recommendationType {
        case .fullWorkout, .lightWorkout:
            if recommendation.plannedExercises.isEmpty {
                throw DailyRecommendationValidationError.workoutPlanHasNoExercises
            }
        case .rest:
            if !recommendation.plannedExercises.isEmpty {
                throw DailyRecommendationValidationError.restPlanHasWorkoutExercises
            }
        case .recovery, .consultation:
            break
        }
    }

    static func reasonText(for error: Error) -> String {
        if let validationError = error as? DailyRecommendationValidationError {
            return validationError.errorDescription ?? String(describing: validationError)
        }
        return error.localizedDescription
    }

    private static func isInvalidExercise(_ exercise: PlannedExercise) -> Bool {
        let hasName = !exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDetail = !exercise.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let validSets = (exercise.targetSets ?? 0) >= 0
        let validReps = (exercise.targetReps ?? 0) >= 0
        return !hasName || !hasDetail || exercise.estimatedMinutes < 0 || !validSets || !validReps
    }

    private static func isInvalidAlternative(_ alternative: AlternativePlan) -> Bool {
        alternative.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || alternative.planDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || alternative.estimatedMinutes < 0
            || alternative.intensity < 1
            || alternative.intensity > 10
    }
}

final class AIPlanGenerationService: PlanGenerationService {
    private let foundationModelClient: FoundationModelClientProtocol
    private let promptBuilder: DailyRecommendationPromptBuilder
    private let calendar: Calendar

    init(
        foundationModelClient: FoundationModelClientProtocol = FoundationModelClientFactory.make(),
        promptBuilder: DailyRecommendationPromptBuilder = DailyRecommendationPromptBuilder(),
        calendar: Calendar = .current
    ) {
        self.foundationModelClient = foundationModelClient
        self.promptBuilder = promptBuilder
        self.calendar = calendar
    }

    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?
    ) async throws -> DailyRecommendation {
        let prompt = promptBuilder.buildDailyRecommendationPrompt(
            checkIn: checkIn,
            goal: goal,
            recentLogs: recentLogs,
            currentPlan: currentPlan
        )

        let date = calendar.startOfDay(for: checkIn.date)
        let firstOutput = try await foundationModelClient.generateDailyRecommendation(prompt: prompt)
        let firstRecommendation = firstOutput.makeModel(date: date, generationSource: .ai)

        do {
            try DailyRecommendationValidator.validate(firstRecommendation)
            return firstRecommendation
        } catch {
            let retryPrompt = promptBuilder.buildDailyRecommendationPrompt(
                checkIn: checkIn,
                goal: goal,
                recentLogs: recentLogs,
                currentPlan: currentPlan,
                previousValidationError: DailyRecommendationValidator.reasonText(for: error)
            )
            let retryOutput = try await foundationModelClient.generateDailyRecommendation(prompt: retryPrompt)
            let retryRecommendation = retryOutput.makeModel(date: date, generationSource: .ai)
            try DailyRecommendationValidator.validate(retryRecommendation)
            return retryRecommendation
        }
    }
}

final class RuleBasedPlanGenerationService: PlanGenerationService {
    private let generator: DailyRecommendationGenerator

    init(generator: DailyRecommendationGenerator = DailyRecommendationGenerator()) {
        self.generator = generator
    }

    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?
    ) async throws -> DailyRecommendation {
        let recommendation = generator.generate(
            checkIn: checkIn,
            goal: goal,
            recentLogs: recentLogs,
            activePlan: currentPlan,
            date: checkIn.date
        )
        recommendation.generationSource = .ruleBased
        recommendation.generationNotice = "今日はAI提案を作れなかったため、チェックイン内容をもとに安全なメニューを提案しています。"
        try DailyRecommendationValidator.validate(recommendation)
        return recommendation
    }
}

final class PlanGenerationCoordinator: PlanGenerationService {
    private let aiService: PlanGenerationService
    private let fallbackService: PlanGenerationService

    init(
        aiService: PlanGenerationService = AIPlanGenerationService(),
        fallbackService: PlanGenerationService = RuleBasedPlanGenerationService()
    ) {
        self.aiService = aiService
        self.fallbackService = fallbackService
    }

    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?
    ) async throws -> DailyRecommendation {
        do {
            let recommendation = try await aiService.generateDailyRecommendation(
                checkIn: checkIn,
                goal: goal,
                recentLogs: recentLogs,
                currentPlan: currentPlan
            )
            try DailyRecommendationValidator.validate(recommendation)
            return recommendation
        } catch {
            let fallback = try await fallbackService.generateDailyRecommendation(
                checkIn: checkIn,
                goal: goal,
                recentLogs: recentLogs,
                currentPlan: currentPlan
            )
            fallback.generationSource = .ruleBased
            fallback.generationNotice = "今日は詳細なプラン生成に失敗しました。代わりに、体調に合わせたシンプルなメニューを用意しました。"
            return fallback
        }
    }
}

struct DailyRecommendationPromptBuilder {
    var calendar: Calendar = .current

    func buildDailyRecommendationPrompt(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        currentPlan: WorkoutPlan?,
        previousValidationError: String? = nil
    ) -> String {
        let goalLines = makeGoalLines(from: goal)
        let planLines = makePlanLines(from: currentPlan)
        let recentLogLines = makeRecentLogLines(from: recentLogs)

        let contextLines = goalLines + planLines + recentLogLines
        let contextSummary = contextLines.isEmpty
            ? "- 目標や過去記録はまだ少ないため、継続しやすさと安全性を優先する。"
            : contextLines.joined(separator: "\n")

        let retryInstruction: String
        if let previousValidationError {
            retryInstruction = """

            # 再生成指示
            前回の出力は invalid でした。
            理由:
            - \(previousValidationError)
            必ず DailyRecommendationOutput の構造と下記制約に従って再生成してください。
            """
        } else {
            retryInstruction = ""
        }

        return """
        あなたはトレーニングアプリのコンディションコーチです。
        ユーザーの今日のチェックイン、目的、最近の記録をもとに、今日の提案を作成してください。
        自由文チャットではなく、UIに保存・表示する DailyRecommendationOutput の構造化出力として返してください。

        # 必須制約
        - 出力は指定された構造に従う
        - readinessLevel は go / easy / rest の3段階で返す
        - recommendationType は fullWorkout / lightWorkout / recovery / rest / consultation から選ぶ
        - 今日の状態に対する理由を reasons に最低2つ含める
        - fullWorkout / lightWorkout の場合は exercises を1つ以上含める
        - rest の場合は exercises を空にする
        - recovery の場合は軽い散歩・ストレッチ・モビリティなどを中心にする
        - alternatives は最低2つ含める
        - 無理に追い込ませない
        - 疲労・睡眠不足・強い筋肉痛がある場合は easy または rest を優先する
        - 休養は失敗ではなく、計画の一部として扱う

        # 今日のチェックイン
        - 睡眠: \(checkIn.sleepQuality.displayName)
        - 疲労: \(checkIn.fatigueLevel.displayName)
        - 気分: \(checkIn.moodLevel.displayName)
        - 筋肉痛: \(checkIn.sorenessLevel.displayName)
        - 使える時間: \(checkIn.availableMinutes)分
        - やる気: \(checkIn.motivationLevel.displayName)
        - メモ: \(checkIn.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? checkIn.note! : "なし")

        # 目的・記録
        \(contextSummary)
        \(retryInstruction)
        """
    }

    private func makeGoalLines(from goal: UserGoal?) -> [String] {
        guard let goal else { return [] }

        var lines = [
            "- 目標タイプ: \(goal.goalType.displayName)",
            "- 目標: \(goal.title)",
            "- 提案方針: \(goal.goalType.policySummary)"
        ]

        if let targetMetric = goal.targetMetric, !targetMetric.isEmpty {
            lines.append("- 目標指標: \(targetMetric)")
        }
        if let targetDate = goal.targetDate {
            lines.append("- 期限: \(targetDate.formatted(date: .abbreviated, time: .omitted))")
        }

        return lines
    }

    private func makePlanLines(from plan: WorkoutPlan?) -> [String] {
        guard let plan else { return [] }
        return [
            "- アクティブプラン: \(plan.title)",
            "- 概要: \(plan.summary)",
            "- 詳細: \(plan.detail)"
        ]
    }

    private func makeRecentLogLines(from logs: [TrainingLog]) -> [String] {
        guard logs.isEmpty == false else { return [] }

        let recent = Array(logs.sorted { $0.date > $1.date }.prefix(5))
        let summaries = TrainingLogAnalytics.dailySummaries(from: recent, calendar: calendar)

        var lines: [String] = []
        for summary in summaries {
            let dayLabel = DateFormatter.hudDay.string(from: summary.date)
            let durationMinutes = summary.totalDurationSec / 60
            let volume = Int(summary.totalVolumeKg.rounded())
            let results = summary.logs.map(\.activityResult.displayName).joined(separator: ",")
            lines.append("- \(dayLabel): \(durationMinutes)分・ボリューム\(volume)kg・結果 \(results)")
        }

        if let latest = recent.first {
            let names = latest.exercises.map(\.name).filter { !$0.isEmpty }
            if names.isEmpty == false {
                lines.append("- 直近の種目: \(names.prefix(3).joined(separator: ", "))")
            }
            if let averageRPE = latest.averageRPE {
                lines.append("- 直近の平均RPE: \(String(format: "%.1f", averageRPE))")
            }
            if let delta = latest.planDeltaSummary, !delta.isEmpty {
                lines.append("- 直近の予定差分: \(delta)")
            }
        }

        return lines
    }
}
