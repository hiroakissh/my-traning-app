# 2. 記録画面

## 2.1. 画面概要

`DailyRecommendation` から開始した予定メニューを、少ない操作で消化するための画面。
詳細な手入力フォームではなく、AIまたはルールベースが作った「今日の処方箋」を実行する画面として扱う。

## 2.2. 表示項目

-   **今日のメニュー見出し:**
    -   `DailyRecommendation.title` と `recommendationType` を表示する。
    -   AIフォールバック時は `generationNotice` を表示する。
-   **予定メニュー:**
    -   `WorkoutSession.exercises` を順番に表示する。
    -   各種目に予定セット数、重量、回数、時間を表示する。
    -   各セットは `ActualSet` として、予定値を初期値に持つ。
-   **セット操作:**
    -   セット完了
    -   重量変更
    -   回数変更
    -   RPE入力
    -   セットスキップ
    -   種目スキップ
-   **タイマー:**
    -   セッション全体の実施時間を計測する。
    -   休憩タイマーはWatch連携時の主要操作にもする。
-   **保存ボタン:**
    -   「セッション終了」で `WorkoutSession` を `TrainingLog` に変換して保存する。

## 2.3. 機能要件

-   **セッション生成:**
    -   `DailyRecommendation.plannedExercises` から `WorkoutSession.exercises` を生成する。
    -   `PlannedSet` と同じ初期値を持つ `ActualSet` を作り、ユーザーは差分だけを記録する。
-   **入力補助:**
    -   初期表示は予定メニューを優先する。
    -   種目追加、種目名編集、詳細な手入力は補助操作とする。
-   **タイマー機能:**
    -   タイマーは画面下部に常に表示され、他の操作を妨げない。
    -   記録開始で計測をスタートし、一時停止/再開/リセットに対応する。
    -   記録終了時に `startTime` / `endTime` / `sessionDurationSec` へ反映し、保存可否の判定に利用する。
-   **データ保存:**
    -   「セッション終了」をタップすると、`WorkoutSession.actualSets` から `TrainingLog` を作成してSwiftDataに保存する。
    -   保存が完了したら、前の画面（ホーム画面など）に戻る。
    -   保存時に `recommendationId`、`workoutSessionId`、`activityResult`、予定との差分、RPE、ユーザーメモを残す。
    -   未完了の予定セットは `skipped` として保存し、単なる未記録にしない。

## 2.4. データ要件

-   `DailyRecommendation` (Domain/Models): 元になった今日の処方箋。
-   `WorkoutSession` (Domain/Models): 実行中の予定/実績セッション。
-   `TrainingLog` (Domain/Models): 終了時に作成される実績記録。
-   `ExerciseDefinition` (Domain/Models): 補助操作で使う過去種目のリスト（サジェスト機能用）。

## 2.5. ヘルスケアデータ連携

-   **取得開始タイミング:** 「記録を開始」ボタン押下時刻を基準にHealthKitへクエリし、セッション開始以降のデータを取得する。
-   **想定する取得データ:**
    -   心拍数（平均/最小/最大）
    -   アクティブエネルギー消費量・安静時エネルギー
    -   歩数
    -   移動距離（ウォーキング/ランニング）
    -   VO2Max（対応デバイスのみ）
    -   HRVやストレス指標（将来拡張）
-   **表示/利用方針:**
    -   記録画面内に取得ステータスとサマリー（例: 平均心拍数、消費カロリー合計、歩数など）を表示。
    -   保存する`TrainingLog`にヘルスケアサマリーを添付し、履歴やAIプラン作成時に活用できるようにする。
