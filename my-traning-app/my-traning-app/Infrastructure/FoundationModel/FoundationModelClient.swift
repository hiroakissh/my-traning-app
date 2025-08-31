import Foundation

// Foundation Model APIクライアントの振る舞いを定義するプロトコル
protocol FoundationModelClientProtocol {
    func generatePlan(prompt: String) async throws -> String
    func generateTodaySuggestion(prompt: String) async throws -> String
}

// 開発・テスト用のモッククライアント
class MockFoundationModelClient: FoundationModelClientProtocol {
    func generatePlan(prompt: String) async throws -> String {
        // 実際のAPI通信を模倣するために2秒待つ
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // ダミーのプラン提案を返す
        let dummyPlan = """
        ## 新しいトレーニングプラン

        ### 長期プラン (3ヶ月)
        - **目標:** 全体的な筋力向上と体力アップ
        - **フォーカス:** 主要な複合関節運動の重量を15%向上させる

        ### 中期プラン (1ヶ月)
        - **フェーズ1:** 筋肥大トレーニング (週4日)
        - **内容:** 胸・背中・脚・肩腕の分割法

        ### 短期プラン (今週)
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
}
