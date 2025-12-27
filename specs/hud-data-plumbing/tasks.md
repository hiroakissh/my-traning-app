# HUDデータ整備 タスクリスト

1. **プランモデルの実装**
   - 対象: `Domain/Models/PlanModels.swift`（新規）
   - `Plan` / `PlanSuggestion` / `PlanProgress` / `PlanMetric` を定義し、進捗率を0〜1にクランプする計算プロパティを持たせる。
2. **RecordingSessionState の進捗計算**
   - 対象: `Domain/Models/RecordingSessionState.swift`（新規）
   - 時間/距離/カロリー/心拍の目標と現在値を保持し、平均心拍を用いた進捗率計算を提供する。
3. **TrainingLog グルーピング・統計ヘルパー**
   - 対象: `Domain/Models/TrainingLog+Analytics.swift`（新規）
   - 日次/週次のグルーピング、総時間・ボリューム・目的別件数の集計関数を追加する。
4. **テスト作成と検証**
   - 対象: `my-traning-appTests` に新規テストファイルを追加し、上記計算ロジックの正常系/境界値をカバーする。
   - `swift test` を実行し、全テストの成功を記録する。
5. **ドキュメント更新**
   - 対象: `specs/hud-data-plumbing/*`、`design_docs/training_record_model.md`
   - 仕様・計画・タスク・研究・データモデル・クイックスタート・契約を更新し、TrainingLog集計とプランモデルの設計背景を反映する。
