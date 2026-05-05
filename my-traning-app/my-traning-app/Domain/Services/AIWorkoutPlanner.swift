import Foundation

@MainActor // UIの更新を伴う可能性があるため、メインスレッドで動作させる
class AIWorkoutPlanner: ObservableObject {
    private let foundationModelClient: FoundationModelClientProtocol
    private let planGenerationService: PlanGenerationService
    private let calendar: Calendar
    
    // 長期プラン用
    @Published var generatedPlan: String = ""
    @Published var planSuggestions: [PlanSuggestion] = []
    
    // 今日の提案用
    @Published var todaySuggestion: String = ""
    @Published var dailyRecommendationOutput: DailyRecommendationOutput?
    @Published var dailyRecommendation: DailyRecommendation?
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // DI (依存性注入) を可能にするイニシャライザ
    init(
        foundationModelClient: FoundationModelClientProtocol = FoundationModelClientFactory.make(),
        planGenerationService: PlanGenerationService? = nil,
        calendar: Calendar = .current
    ) {
        self.foundationModelClient = foundationModelClient
        self.planGenerationService = planGenerationService ?? PlanGenerationCoordinator(
            aiService: AIPlanGenerationService(
                foundationModelClient: foundationModelClient,
                calendar: calendar
            ),
            fallbackService: RuleBasedPlanGenerationService()
        )
        self.calendar = calendar
    }
    
    func createPlan(userProfile: UserProfile, goal: String) async {
        isLoading = true
        errorMessage = nil
        generatedPlan = ""
        planSuggestions = []
        
        // ユーザー情報からプロンプトを生成
        let prompt = """
        以下のユーザー情報と目標に基づいて、最適なトレーニングプランを提案してください。
        マークダウンを使わず、プレーンテキストのみで回答してください。箇条書きはハイフン区切りで構いません。

        # ユーザー情報
        - 年齢: \(userProfile.age)歳
        - 性別: \(userProfile.gender)
        - 身長: \(userProfile.height)cm
        - 体重: \(userProfile.weight)kg

        # 目標
        \(goal)
        """
        
        do {
            let plan = try await foundationModelClient.generatePlan(prompt: prompt)
            self.generatedPlan = plan
            self.planSuggestions = PlanSuggestionMapper.map(from: plan, prompt: prompt)
        } catch {
            self.errorMessage = mapError(error)
            self.generatedPlan = ""
            self.planSuggestions = []
        }

        isLoading = false
    }

    func generateDailyRecommendation(
        checkIn: DailyCheckIn,
        goal: UserGoal?,
        recentLogs: [TrainingLog],
        activePlan: ActivePlan?
    ) async {
        isLoading = true
        errorMessage = nil
        dailyRecommendationOutput = nil
        dailyRecommendation = nil

        do {
            let recommendation = try await planGenerationService.generateDailyRecommendation(
                checkIn: checkIn,
                goal: goal,
                recentLogs: recentLogs,
                currentPlan: activePlan
            )
            dailyRecommendation = recommendation
            dailyRecommendationOutput = DailyRecommendationOutput(recommendation: recommendation)
            if recommendation.generationSource == .ruleBased {
                errorMessage = recommendation.generationNotice
            }
        } catch {
            errorMessage = mapError(error)
            dailyRecommendationOutput = nil
            dailyRecommendation = nil
        }

        isLoading = false
    }

    func suggestTodayWorkout(prompt: String) async {
        let context = AIAssistantContext(
            userQuery: prompt,
            activePlan: nil,
            recentLogs: [],
            healthSnapshot: nil,
            dailyGoalKcal: nil
        )
        await suggestTodayWorkout(prompt: prompt, context: context)
    }

    func suggestTodayWorkout(prompt: String, context: AIAssistantContext) async {
        isLoading = true
        errorMessage = nil
        todaySuggestion = ""
        
        do {
            let promptWithContext = buildContextualPrompt(userPrompt: prompt, context: context)
            let suggestion = try await foundationModelClient.generateTodaySuggestion(prompt: promptWithContext)
            self.todaySuggestion = suggestion
        } catch {
            self.errorMessage = mapError(error)
            self.todaySuggestion = ""
        }

        isLoading = false
    }

    private func mapError(_ error: Error) -> String {
        if let foundationError = error as? FoundationModelError {
            switch foundationError {
            case .unavailable(let status):
                return status.guidanceMessage
            case .sessionUnavailable:
                return "AIセッションを初期化できませんでした。デバイスの状態を確認してから再試行してください。"
            case .generationFailed(let underlyingError):
                return "AIからの応答生成に失敗しました。時間を置いて再度お試しください。（詳細: \(underlyingError.localizedDescription))"
            }
        }

        let nsError = error as NSError
        return "想定外のエラーが発生しました。（コード: \(nsError.code))"
    }

    private func buildContextualPrompt(userPrompt: String, context: AIAssistantContext) -> String {
        let recentLogLines = makeRecentLogLines(from: context.recentLogs)
        let healthLines = makeHealthLines(from: context.healthSnapshot, goal: context.dailyGoalKcal)
        let planLines = makePlanLines(from: context.activePlan)

        let todayOverview: String
        if healthLines.isEmpty && recentLogLines.isEmpty && planLines.isEmpty {
            todayOverview = "- 手元の進捗データはまだありません。安全第一で無理のない提案にしてください。"
        } else {
            todayOverview = (planLines + healthLines + recentLogLines).joined(separator: "\n")
        }

        return """
        以下の最新データを踏まえて、ユーザーの質問に対して日本語で簡潔に提案してください。リスクを避け、ウォームアップや休息も含めた安全な提案を優先してください。
        マークダウンは使わず、プレーンテキストのみで回答してください。

        # ユーザーの質問
        \(userPrompt)

        # 状況サマリー
        \(todayOverview)
        """
    }

    private func makePlanLines(from plan: ActivePlan?) -> [String] {
        guard let plan else { return [] }
        return [
            "- アクティブプラン: \(plan.title)",
            "- 概要: \(plan.summary)"
        ]
    }

    private func makeHealthLines(from snapshot: HealthDataSnapshot?, goal: Double?) -> [String] {
        guard let snapshot else { return [] }
        var lines: [String] = []

        if let energy = snapshot.totalEnergyBurned {
            if let goal {
                lines.append("- 今日の消費エネルギー: \(Int(energy.rounded())) kcal / \(Int(goal)) kcal")
            } else {
                lines.append("- 今日の消費エネルギー: \(Int(energy.rounded())) kcal")
            }
        }

        if let distance = snapshot.distanceWalkingRunning {
            lines.append("- 今日の移動距離: \(String(format: "%.1f", distance)) km")
        }

        if let heartRate = snapshot.averageHeartRate {
            lines.append("- 平均心拍数: \(Int(heartRate)) bpm")
        }

        if let steps = snapshot.stepCount {
            lines.append("- 歩数: \(steps) steps")
        }

        return lines
    }

    private func makeRecentLogLines(from logs: [TrainingLog]) -> [String] {
        guard logs.isEmpty == false else { return [] }

        let recent = Array(logs.sorted { $0.date > $1.date }.prefix(3))
        let summaries = TrainingLogAnalytics.dailySummaries(from: recent, calendar: calendar)

        var lines: [String] = []
        for summary in summaries {
            let dayLabel = DateFormatter.hudDay.string(from: summary.date)
            let durationMinutes = summary.totalDurationSec / 60
            let volume = Int(summary.totalVolumeKg.rounded())
            let purposes = summary.purposeCounts.keys.map { $0.displayName }.sorted().joined(separator: ",")
            lines.append("- \(dayLabel): \(durationMinutes)分・ボリューム\(volume)kg・目的 \(purposes)")
        }

        if let latest = recent.first {
            let names = latest.exercises.map(\.name).filter { !$0.isEmpty }
            if names.isEmpty == false {
                lines.append("- 直近の種目: \(names.prefix(3).joined(separator: ", "))")
            }
        }

        return lines
    }
}

// ダミーのユーザープロフィール（本来は永続化されたデータを使用）
struct UserProfile {
    let age: Int
    let gender: String
    let height: Int
    let weight: Int
}

struct AIAssistantContext {
    let userQuery: String
    let activePlan: ActivePlan?
    let recentLogs: [TrainingLog]
    let healthSnapshot: HealthDataSnapshot?
    let dailyGoalKcal: Double?
}
