import Foundation

@MainActor // UIの更新を伴う可能性があるため、メインスレッドで動作させる
class AIWorkoutPlanner: ObservableObject {
    private let foundationModelClient: FoundationModelClientProtocol
    
    // 長期プラン用
    @Published var generatedPlan: String = ""
    
    // 今日の提案用
    @Published var todaySuggestion: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // DI (依存性注入) を可能にするイニシャライザ
    init(foundationModelClient: FoundationModelClientProtocol = LiveFoundationModelClient()) {
        self.foundationModelClient = foundationModelClient
    }
    
    func createPlan(userProfile: UserProfile, goal: String) async {
        isLoading = true
        errorMessage = nil
        generatedPlan = ""
        
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
        } catch {
            self.errorMessage = "プランの生成に失敗しました: \(error.localizedDescription)"
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
            self.errorMessage = "提案の生成に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// ダミーのユーザープロフィール（本来は永続化されたデータを使用）
struct UserProfile {
    let age: Int
    let gender: String
    let height: Int
    let weight: Int
}
