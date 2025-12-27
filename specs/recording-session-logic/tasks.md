# 記録セッションロジック タスクリスト

1. **目標タイプ別バリデーションユースケースの追加**
   - 対象: `Domain/Services` 新規ファイル
   - 目的ごとの最小メニュー件数と最小経過秒数を判定し、CTA可否と理由を返す`RecordingSessionValidator`を実装する。
   - 全目的のパターンを網羅するユニットテストを追加し、先に失敗を確認する。
2. **計測状態モデルとフォーマッタの実装**
   - 対象: `Domain/Services` 新規 or 既存ファイル
   - 開始・一時停止・リセット・経過秒更新を扱うタイマー状態モデルを作成し、表示用の時間フォーマッタヘルパーを追加する。
   - 経過秒の増分とフォーマットのユニットテストを作成する。
3. **SwiftData 永続化の接続**
   - 対象: `Application/my_traning_appApp.swift`、`Presentation/Views/RecordingView.swift`
   - `modelContainer`を設定し、`ModelContext`から`TrainingLog`/`TrainingExercise`/`TrainingSet`を保存できるようにする。
   - メニュー選択から`TrainingExercise`配列を生成するヘルパーを実装し、保存エラーハンドリングを整備する。
4. **RecordingViewのUI更新**
   - 対象: `Presentation/Views/RecordingView.swift`
   - 目的ピッカー、バリデーション文言、ライブタイマー、CTA（開始・一時停止/再開・リセット・終了して保存）を追加し、バリデーションと連動させる。
   - 保存成功時のリセットとトースト/メッセージ表示を実装する。
5. **リグレッションテスト実行**
   - `swift test`を実行し、結果を記録する。
