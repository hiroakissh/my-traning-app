import Foundation

// Foundation Model APIクライアントの振る舞いを定義するプロトコル
protocol FoundationModelClientProtocol {
    func generatePlan(prompt: String) async throws -> String
    func generateTodaySuggestion(prompt: String) async throws -> String
    func generateDailyRecommendation(prompt: String) async throws -> DailyRecommendationOutput
}

// 開発・テスト用のモッククライアント
class MockFoundationModelClient: FoundationModelClientProtocol {
    func generatePlan(prompt: String) async throws -> String {
        // 実際のAPI通信を模倣するために2秒待つ
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // ダミーのプラン提案を返す
        let dummyPlan = """
        ## 新しいトレーニングプラン

        ### Goal（目標）
        - **目標:** 全体的な筋力向上と体力アップ
        - **フォーカス:** 主要な複合関節運動の重量を15%向上させる

        ### Phase（今のフェーズ）
        - **方針:** 筋肥大トレーニング (週4日)
        - **内容:** 胸・背中・脚・肩腕の分割法

        ### Week（今週の作戦）
        - **月:** 胸の日 (ベンチプレス中心)
        - **火:** 脚の日 (スクワット中心)
        - **水:** 休息
        - **木:** 背中の日 (デッドリフト、懸垂)
        - **金:** 肩・腕の日
        - **土日:** 休息または軽い有酸素運動
        """
        
        return dummyPlan
    }
    
    func generateTodaySuggestion(prompt: String) async throws -> String {
        // 短い応答なので、少し短い待ち時間
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        if prompt.contains("忙しい") || prompt.contains("時間がない") {
            return "承知しました。時間がない日ですね。短時間で集中して行える胸のトレーニングはいかがでしょうか？ベンチプレスを3セット、その後プッシュアップを限界まで3セット行いましょう。"
        } else if prompt.contains("追い込みたい") {
            return "お任せください！追い込みたい日ですね。脚のトレーニングで限界に挑戦しましょう。スクワットを5セット、その後レッグプレスとランジをスーパーセットで行うのはいかがでしょうか？"
        } else {
            return "ご質問ありがとうございます。今日は背中の日です。デッドリフトでウォーミングアップした後、懸垂とラットプルダウンを重点的に行い、広背筋を鍛えましょう。"
        }
    }

    func generateDailyRecommendation(prompt: String) async throws -> DailyRecommendationOutput {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        if prompt.contains("疲労: 重い") || prompt.contains("筋肉痛: 強い") {
            return DailyRecommendationOutput(
                readinessLevel: .rest,
                recommendationType: .rest,
                title: "回復を優先する日",
                summary: "今日は休むことを計画の一部として扱います。軽い回復行動だけで十分です。",
                reasons: [
                    "疲労感が高く、回復不足の可能性があります。",
                    "強い筋肉痛がある場合は高負荷を避けます。",
                    "休養も計画遵守の一部として記録します。"
                ],
                exercises: [],
                alternatives: [
                    AlternativePlanOutput(title: "完全休養", description: "運動せず睡眠と食事を整える", estimatedMinutes: 0, intensity: 1),
                    AlternativePlanOutput(title: "散歩だけ", description: "10分だけ外に出る", estimatedMinutes: 10, intensity: 1),
                    AlternativePlanOutput(title: "AIに相談", description: "痛みや不安がある場合だけ相談する", estimatedMinutes: 5, intensity: 1)
                ],
                recoveryAdvice: [
                    "休んでも計画は崩れていません。",
                    "水分を多めに取り、睡眠を優先してください。"
                ]
            )
        }

        return DailyRecommendationOutput(
            readinessLevel: .easy,
            recommendationType: .lightWorkout,
            title: "上半身ライト",
            summary: "今日は軽めがおすすめです。フォーム確認と短い有酸素で継続を優先します。",
            reasons: [
                "チェックイン情報から追い込みすぎない方が続けやすい状態です。",
                "使える時間に合わせて種目数を絞ります。",
                "目的に対して今日できる最小の前進を作ります。"
            ],
            exercises: [
                PlannedExerciseOutput(name: "ベンチプレス", detail: "重量を追わずフォーム確認", targetSets: 3, targetReps: 8, weightDescription: "軽め", estimatedMinutes: 12, category: .strength),
                PlannedExerciseOutput(name: "ダンベルロー", detail: "反動を使わず丁寧に引く", targetSets: 3, targetReps: 10, weightDescription: "軽中重量", estimatedMinutes: 10, category: .strength),
                PlannedExerciseOutput(name: "有酸素", detail: "息が上がりすぎない強度", targetSets: nil, targetReps: nil, weightDescription: nil, estimatedMinutes: 10, category: .cardio)
            ],
            alternatives: [
                AlternativePlanOutput(title: "このメニューで開始", description: "提案メニューをそのまま実行する", estimatedMinutes: 30, intensity: 4),
                AlternativePlanOutput(title: "10分版に短縮", description: "最初の1種目だけ実行する", estimatedMinutes: 10, intensity: 2),
                AlternativePlanOutput(title: "休養日にする", description: "疲労が強い場合は休養として記録する", estimatedMinutes: 0, intensity: 1)
            ],
            recoveryAdvice: [
                "終わった後に余力が残る強度で止めます。",
                "痛みがある動きは避けてください。"
            ]
        )
    }
}
