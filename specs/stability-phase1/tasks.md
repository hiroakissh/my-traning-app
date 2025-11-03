# 安定化フェーズ1 タスクリスト

1. **利用可否抽象の追加**
   - 対象ファイル: `Infrastructure/FoundationModel/LiveFoundationModelClient.swift`
   - `FoundationModelAvailabilityStatus` を導入し、利用可否チェックをクラッシュしない `FoundationModelError` へリファクタリングする。
   - セッション初期化を利用可否判定後に行えるよう調整する。
   - `my_traning_appTests` に利用可否分岐を網羅するテストを追加する。
2. **プランナーでの構造化エラーマッピング**
   - 対象ファイル: `Domain/Services/AIWorkoutPlanner.swift`
   - `FoundationModelError` をローカライズ済み文言へ変換するヘルパーを追加する。
   - `createPlan` と `suggestTodayWorkout` の双方でヘルパーを利用し、失敗時は生成内容をリセットする。
   - `AIWorkoutPlannerTests` を拡張し、各エラー種別で期待するメッセージを検証する。
3. **ホーム／プランニング UI のメッセージ更新**
   - 対象ファイル: `Presentation/Views/HomeView.swift`、`Presentation/Views/PlanningView.swift`
   - 説明文をより具体的な日本語コピーへ更新し、`PlanningView` の重複プレビューを削除する。
   - 読み込み中はリトライボタンが無効化される挙動を維持する。
4. **バンドルデコードの安全化**
   - 対象ファイル: `Utilities/Bundle+Decoder.swift`、`Presentation/Views/RecordingView.swift`
   - デコーダーを `throws` 化し、記録画面からは `Result` を通じてエラーを扱えるようにする。
   - 失敗時に画面でインラインメッセージを表示する実装を追加する。
   - 欠損データ／不正データを検証するユニットテストを用意する。
5. **リグレッションテスト実行**
   - `swift test` を実行し、結果を PR に記録する。
