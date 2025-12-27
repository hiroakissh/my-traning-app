# 履歴フィルタリング タスク一覧

1. **履歴メタデータ生成の追加**
   - 対象: `Domain/Models`（拡張ファイル追加）
   - `TrainingLog` からタイトル・概要・カテゴリ/部位・検索対象文字列を生成するヘルパーを実装する。
   - 目的・カテゴリの表示名ヘルパーを整備する。
2. **検索・カテゴリ・日付フィルタのロジック実装**
   - 対象: `Domain/Services` または `Utilities`（新規ファイル）
   - 検索テキスト、`ExerciseCategory`、日付の AND 条件で `TrainingHistoryItem` を絞り込む関数を実装する。
   - 先にユニットテストを追加し、検索/カテゴリ/日付の組み合わせを検証する。
3. **HistoryView のデータソース置き換えと UI 拡張**
   - 対象: `Presentation/Views/HistoryView.swift`
   - `@Query` で SwiftData の `TrainingLog` を取得し、ダミーデータを削除する。
   - 検索バーとカテゴリフィルタ UI を追加し、リスト・カレンダー・分析表示を実ログベースに更新する。
   - ログの詳細ビューへ遷移するナビゲーションを実装する。
4. **詳細ビューの追加**
   - 対象: `Presentation/Views`（新規ファイル）
   - ログの日付・目的・所要時間・種目/セットを表示する詳細ビューを作成する。
5. **SwiftData コンテナの提供とプレビュー整備**
   - 対象: `Application/my_traning_appApp.swift` ほかプレビュー用補助コード
   - アプリ起動時に `TrainingLog` 系モデルのコンテナを注入し、履歴画面プレビュー用のサンプルデータ生成を行う。
6. **設計ドキュメント更新**
   - 対象: `design_docs/screen_specifications/03_history.md` ほか関連ドキュメント
   - 画面構成（検索/カテゴリフィルタ、カレンダー同期、詳細遷移、分析集計）の反映を行う。
