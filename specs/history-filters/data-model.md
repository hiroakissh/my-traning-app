# 履歴フィルタリング データモデルノート

## 対象モデル
- `TrainingLog`: 日付、目的、所要時間、ノート、`TrainingExercise` 配列を保持。
- `TrainingExercise`: 種目名、`ExerciseCategory`、`BodyPart`、`TrainingSet` 配列を保持。
- `TrainingSet`: セット番号、重量/回数または時間、RPE 等を保持。

## 履歴表示で利用する派生情報
- **主要種目名:** `exercises.first?.name` を優先し、ない場合は「トレーニング」などの汎用タイトル。
- **カテゴリ集合:** `exercises.map(\.category)` をユニーク化。フィルタ判定は集合に含まれるかどうかで行う。
- **部位集合:** `exercises.map(\.bodyPart)` をユニーク化し、サマリー表示に利用。
- **セット数:** `exercises.flatMap(\.sets).count` を合計して概要に表示。
- **検索対象文字列:** 種目名リスト、ノート、目的表示名、部位表示名を連結して部分一致検索に利用。
- **日付判定:** `Calendar.isDate(_:inSameDayAs:)` で日付フィルタリングを行い、カレンダー選択とリストを同期する。

## 表示用の付加情報
- 目的の表示名（例: `hypertrophy` → 「筋肥大」）とカテゴリの表示名（例: `strength` → 「筋トレ」）をヘルパーで提供し、UI とテストで共通利用する。
- 日付表示は `yyyy/MM/dd (E)` 形式を基本とし、週内の比較には `Calendar` の weekdaySymbol を利用する。
