# HUDデータ整備 契約

## PlanProgress/PlanMetric
- `PlanMetric.progressRate` は `currentValue/targetValue` を0〜1でクランプする。`targetValue <= 0` の場合は 0 とする。
- `PlanProgress.overallRate` は `metrics.progressRate` の平均を基本とし、メトリクスが空の場合は 0。

## RecordingSessionState
- time/distance/calorie/heartRate いずれも目標未設定時は `nil` を返す。
- 心拍進捗はサンプル平均と `targets.averageHeartRate` の比率。サンプルが空の場合は `nil`。
- 進捗値はすべて 0〜1 にクランプする。

## TrainingLog Analytics
- ボリューム計算から `isWarmup == true` のセットを除外する。
- `weightKg` と `reps` が両方存在するセットのみボリュームに含める。
- 日次サマリは同日付のログを集約し、週次サマリは週の開始日（Calendarの`weekday`設定に依存）でグルーピングする。
