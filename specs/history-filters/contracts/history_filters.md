# 履歴フィルタリング コントラクト

## フィルタロジック
- 入力: `TrainingHistoryItem` 配列、検索文字列（任意）、`ExerciseCategory?`、日付（任意）、`Calendar`。
- 出力: 入力順を維持したまま、以下の AND 条件を満たすアイテムのみを返す。
  1. カテゴリフィルタが指定されていれば `categories` に含まれる。
  2. 日付が指定されていれば `Calendar.isDate(item.date, inSameDayAs: date)` を満たす。
  3. 検索文字列が空でなければ、`searchableText.lowercased()` が検索文字列に部分一致する。

## メタデータ生成
- 入力: `TrainingLog`、`Calendar`、`DateFormatter`。
- 出力: `TrainingHistoryItem`（id、date、dateLabel、title、subtitle、categories、bodyParts、totalSets、searchableText、元の `TrainingLog` 参照）。
- 期待値:
  - `title`: 主要種目名（`exercises.first?.name`）を優先し、未入力なら「トレーニング」。
  - `subtitle`: 目的表示名、セット合計、部位表示名を含む短い概要。
  - `categories`/`bodyParts`: 種目からユニーク化した集合。
  - `searchableText`: 種目名リスト、ノート、目的表示名、部位表示名を結合した文字列。

## UI 同期
- リストモードは検索バーとカテゴリフィルタを提供し、フィルタ結果を `NavigationLink` で詳細に遷移させる。
- カレンダーモードでは選択日付を日付フィルタに設定し、同条件のログをリスト表示する。
- 分析モードは実ログベースの集計チャートを描画し、データがない場合は案内テキストを表示する。
