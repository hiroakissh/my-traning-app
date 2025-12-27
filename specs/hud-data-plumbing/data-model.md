# HUDデータ整備 データモデル

## Plan
| フィールド | 型 | 説明 |
| --- | --- | --- |
| id | UUID | プラン識別子 |
| title | String | プランタイトル（例: ベンチプレス100kgチャレンジ） |
| horizon | PlanHorizon | 長期/中期/短期の区分 |
| startDate | Date | プラン開始日 |
| endDate | Date | プラン終了予定日 |
| status | PlanStatus | 進行中/完了/一時停止などの状態 |
| metrics | [PlanMetric] | 目標達成度を表すメトリクス配列 |
| progress | PlanProgress | 総合進捗（達成率や継続日数） |
| suggestions | [PlanSuggestion] | AIやユーザー入力による改善提案履歴 |

## PlanSuggestion
| フィールド | 型 | 説明 |
| --- | --- | --- |
| id | UUID | 提案の一意ID |
| message | String | 提案内容 |
| createdAt | Date | 生成日時 |
| source | SuggestionSource | `ai`/`user`/`system` などの発生元 |

## PlanProgress
| フィールド | 型 | 説明 |
| --- | --- | --- |
| overallRate | Double | 総合進捗率（0〜1でクランプ） |
| streakDays | Int | 連続実施日数 |
| completedMilestones | Int | 達成済みマイルストン数 |
| totalMilestones | Int | 設定されたマイルストン総数 |
| metrics | [PlanMetric] | メトリクスごとの進捗詳細 |

## PlanMetric
| フィールド | 型 | 説明 |
| --- | --- | --- |
| name | String | メトリクス名（例: ベンチプレス重量） |
| unit | String | 表示単位（kg, km, kcal, bpm など） |
| currentValue | Double | 現在値 |
| targetValue | Double | 目標値（0を許容しない前提で計算時にガード） |
| progressRate | Double | `currentValue/targetValue` を 0〜1 にクランプした値 |
| trend | ProgressTrend | 増加/減少/横ばいの傾向 |

## RecordingSessionState
| フィールド | 型 | 説明 |
| --- | --- | --- |
| elapsed | TimeInterval | 経過時間（秒） |
| distance | Double | 移動距離（メートル） |
| activeCalories | Double | 消費カロリー（kcal） |
| heartRateSamples | [Double] | 心拍サンプル (bpm) |
| targets | SessionTargets | 目標値（時間/距離/カロリー/平均心拍） |
| timeProgress | Double? | 目標がある場合の時間進捗率（0〜1）、未設定ならnil |
| distanceProgress | Double? | 距離進捗率（0〜1） |
| calorieProgress | Double? | カロリー進捗率（0〜1） |
| heartRateProgress | Double? | 平均心拍に対する進捗率（0〜1） |
| averageHeartRate | Double? | 心拍サンプルの平均値 |

## TrainingLog Analytics 出力
| エンティティ | 型 | 説明 |
| --- | --- | --- |
| DailyLogSummary | struct | `date`、`logs`、`totalDurationSec`、`totalVolumeKg`、`purposeCounts` を保持 |
| WeeklyLogSummary | struct | `weekOfYear`（開始日）、`dailySummaries`、週次合計時間/ボリュームを保持 |
| purposeCounts | [TrainingPurpose: Int] | 目的別のセッション数 |

### ボリューム計算
- `TrainingSet` の `isWarmup == true` は除外。
- `weightKg` と `reps` が存在するセットのみ `weightKg * Double(reps)` を加算。
- cardio/mobility など重量が無いセットはボリューム0として扱う。
