# HUDデータ整備 Quickstart

1. 依存関係なし：Swift Package の追加は行っていないため、`xcodebuild`や`swift test`のみで確認可能。
2. テスト実行：リポジトリルートで `swift test` を実行し、Plan/RecordingSessionState/TrainingLog集計のユニットテストが通過することを確認。
3. サンプル利用：
   - `PlanProgress.overallRate` で総合進捗を取得し、ホームのプログレスバーに渡す。
   - `RecordingSessionState` に目標値を設定し、`timeProgress` 等の Optional を UI でバインドする。
   - `TrainingLogAnalytics.weeklySummaries(from:)` を呼び、履歴画面の週次グラフデータとして利用する。
4. ロールバック：問題発生時は `feature/hud-data-plumbing` ブランチのコミットをリバート。データ移行は不要。
