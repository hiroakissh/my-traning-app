import Foundation

@MainActor // UIの更新を伴う可能性があるため、メインスレッドで動作させる
class AIWorkoutPlanner: ObservableObject {
    private let foundationModelClient: FoundationModelClientProtocol
    
    // 長期プラン用
    @Published var generatedPlan: String = ""
    @Published var planSuggestions: [PlanSuggestion] = []
    
    // 今日の提案用
    @Published var todaySuggestion: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // DI (依存性注入) を可能にするイニシャライザ
    init(foundationModelClient: FoundationModelClientProtocol = FoundationModelClientFactory.make()) {
        self.foundationModelClient = foundationModelClient
    }
    
    func createPlan(userProfile: UserProfile, goal: String) async {
        isLoading = true
        errorMessage = nil
        generatedPlan = ""
        planSuggestions = []
        
        // ユーザー情報からプロンプトを生成
        let prompt = """
        以下のユーザー情報と目標に基づいて、最適なトレーニングプランを提案してください。

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

    func suggestTodayWorkout(prompt: String) async {
        isLoading = true
        errorMessage = nil
        todaySuggestion = ""
        
        do {
            let suggestion = try await foundationModelClient.generateTodaySuggestion(prompt: prompt)
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
}

// ダミーのユーザープロフィール（本来は永続化されたデータを使用）
struct UserProfile {
    let age: Int
    let gender: String
    let height: Int
    let weight: Int
}
