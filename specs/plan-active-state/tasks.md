# プランアクティブ状態管理 タスク

1. **AI応答マッピングの追加**
   - 対象: `Domain/Models`、`Domain/Services`
   - `PlanHorizon`/`PlanSuggestion`モデルと`PlanSuggestionMapper`を実装し、Markdown応答を長期/中期/短期セクションへ分割するテストを作成する。
2. **プラン永続化モデルの導入**
   - 対象: `Domain/Models`、`Application/my_traning_appApp.swift`
   - `ActivePlan` SwiftDataモデルを追加し、ModelContainerに登録する。保存・取得のテストを追加する。
3. **AIプランナーの状態更新**
   - 対象: `Domain/Services/AIWorkoutPlanner.swift`
   - `generatePlan`結果を`PlanSuggestion`へマッピングするよう変更し、エラー時のリセット・テストを拡張する。
4. **プランニングUIのアクティブ/候補表示と変更フロー**
   - 対象: `Presentation/Views/PlanningView.swift`
   - アクティブプランカード、再提案、他候補一覧、採用（変更）アクションを実装する。読みやすいレイアウトとエラー状態の表示を整える。
5. **ホーム画面へのアクティブプラン共有**
   - 対象: `Presentation/Views/HomeView.swift`
   - アクティブプラン概要カードを追加し、未設定時の案内を表示する。
6. **リグレッションテスト実行**
   - 対象: テストスイート
   - `swift test`を実行し、結果を記録する。
