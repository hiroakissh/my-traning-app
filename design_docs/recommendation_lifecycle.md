# Recommendation Lifecycle

このアプリの中心ループは、チェックインから今日の処方箋を作り、実行中セッションを経由して記録し、週次レビューから次回提案へ戻す流れである。

```text
DailyCheckIn
↓ generate
DailyRecommendation
↓ start
WorkoutSession
↓ finish
TrainingLog
↓ aggregate
WeeklyReview
↓ next recommendation
Next DailyRecommendation
```

## 各モデルの責務

### DailyCheckIn

実行前の状態を表す。睡眠、疲労、気分、筋肉痛、使える時間、やる気、任意メモを保存する。

この値はAI生成とルールベース生成の共通入力であり、今日の提案理由に必ず反映する。

### DailyRecommendation

今日の処方箋を表す。`readinessLevel`、`recommendationType`、タイトル、要約、理由、予定メニュー、代替案、回復アドバイスを持つ。

生成は `PlanGenerationService` 経由で行う。AI出力は `DailyRecommendationValidator` で検証し、不正な場合は1回だけ修正プロンプト付きで再生成する。再生成後も不正、またはAIが利用できない場合は `RuleBasedPlanGenerationService` にフォールバックする。

`rest` の場合、`plannedExercises` は空にする。休養日にやることは `recoveryAdvice` に入れる。

### WorkoutSession

`DailyRecommendation` と `TrainingLog` の間にある実行中セッション。

開始時に `DailyRecommendation.plannedExercises` から `WorkoutSession.exercises` を生成する。各予定セットには、同じ初期値を持つ `ActualSet` を作る。ユーザーは予定を消化しながら、完了、変更、RPE、スキップを記録する。

主操作:

- セット完了
- 重量変更
- 回数変更
- RPE入力
- セットスキップ
- 種目スキップ
- セッション終了

ゼロから種目を追加する操作は補助導線とする。

### TrainingLog

実行結果を表す。次回提案の材料として、以下を保存する。

- `recommendationId`
- `workoutSessionId`
- `goalId`
- `activityResult`
- 実施種目とセット
- 実施時間
- 平均RPE
- ユーザーメモ
- 予定通りかどうか
- 短縮したかどうか
- 一部スキップしたかどうか
- 休養に変更したかどうか
- 予定との差分

`rested` と `skipped` は分ける。

- `rested`: アプリ提案またはユーザー判断により、計画的に休んだ
- `skipped`: 何もせず、実行も記録もしなかった

休養は失敗ではなく、次回提案に戻すための有効なログとして扱う。

### WeeklyReview

週単位で `TrainingLog`、`DailyCheckIn`、`DailyRecommendation`、`ActivityResult`、RPE、planned vs actual の差分を集約する。

生成タイミング:

- 週の終わりに自動生成
- ユーザーが「今週の振り返り」を開いたときに生成

表示項目:

- 予定に対する実施率
- 休養日数
- スキップ数
- 疲労が高かった日
- パフォーマンスが良かった日
- 来週の作戦

次回提案に返す検出項目:

- 予定が重すぎる
- 休養が不足している
- 睡眠不足の日に失敗しやすい
- 特定部位の疲労が残りやすい
- 使える時間に対してメニューが長すぎる
- 週後半に継続率が落ちる

## 変換タイミング

### Check-in完了時

1. `DailyCheckIn` を保存する
2. `PlanGenerationCoordinator` が `AIPlanGenerationService` を呼ぶ
3. `DailyRecommendationValidator` が結果を検証する
4. 不正なら1回だけ再生成する
5. 失敗時は `RuleBasedPlanGenerationService` が安全な提案を返す
6. `DailyRecommendation` を保存する

ユーザー向け表示は「AI生成に失敗しました」だけで終わらせない。フォールバック時は「今日はAI提案を作れなかったため、チェックイン内容をもとに安全なメニューを提案しています。」のように表示する。

### セッション開始時

1. ユーザーが「このメニューで開始」を押す
2. `WorkoutSessionLifecycleService.makeSession(from:)` が `WorkoutSession` を作る
3. `PlannedExercise` から `WorkoutSessionExercise` と `PlannedSet` / `ActualSet` を作る
4. `WorkoutSessionView` に予定メニューを最初から表示する

### セッション終了時

1. 未完了の予定セットはスキップ扱いにする
2. `WorkoutSession.status` を `completed` / `partiallyCompleted` / `cancelled` に確定する
3. `WorkoutSessionLifecycleService.makeTrainingLog(from:)` が `TrainingLog` を作る
4. `TrainingLog` に実績、RPE、予定との差分、実施時間を保存する

### 休養記録時

1. ユーザーが「この内容で休養を記録」または「休む」を押す
2. `WorkoutSession` は作らず、`TrainingLog.activityResult = rested` として保存する
3. トレーニング提案から休養へ変えた場合は `changedToRest = true` を保存する

## Apple Watch方針

Apple Watchは最小操作端末とする。

Watchで扱う:

- 今日のメニュー確認
- ワークアウト開始
- 現在の種目・セット確認
- セット完了
- 休憩タイマー
- RPE簡易入力
- セッション終了

Watchで避ける:

- 種目の細かい追加
- 種目名の編集
- 重量の細かい編集
- 回数の細かい編集
- 長文メモ入力
- AIとの長文チャット

WatchのRPEは3段階から始める。

```swift
enum SimpleRPE {
    case easy    // RPE 5
    case normal  // RPE 7
    case hard    // RPE 9
}
```
