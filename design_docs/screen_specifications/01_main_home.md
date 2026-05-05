# 1. メイン画面 (ホーム)

## 1.1. 画面概要

アプリ起動時に最初に表示される画面。ユーザーが毎日迷う「運動する・軽く動く・休む」の意思決定を支援する。
ホームの主役はAIチャットではなく、チェックインから生成される「今日の処方箋」とする。

## 1.2. 表示項目

表示優先順位:

1.  **TodayRecommendationCard**
    -   今日のおすすめアクション
    -   今日の状態判定（`go` / `easy` / `rest`）
    -   提案理由
    -   推奨メニュー
    -   代替アクション
    -   開始ボタン
    -   休む選択肢
2.  **DailyCheckInCard**
    -   今日のチェックイン状況
    -   未入力の場合はチェックイン導線
    -   入力済みの場合は睡眠、疲労、使える時間の要約と更新導線
3.  **今日の予定メニュー**
    -   `DailyRecommendation.plannedExercises` を並べる
    -   休養日でも散歩、ストレッチ、明日の確認などを表示する
4.  **今週の進捗**
    -   今週の実行回数
    -   休養日数
    -   休養を含めた計画遵守率
5.  **AI相談ボタン**
    -   補助導線として配置
6.  **最近の記録**

## 1.3. 機能要件

-   **TodayRecommendationCard表示:**
    -   当日の`DailyRecommendation`がある場合は最上部に表示する。
    -   未生成の場合は「チェックインする」ボタンを表示する。
    -   `RecommendationType.rest` / `recovery` もトレーニング提案と同じレベルで扱う。
-   **Daily Check-In導線:**
    -   `DailyCheckInView`へ遷移し、数タップで状態入力できる。
    -   入力後にAIの構造化提案、またはルールベース提案を生成する。
-   **TodayRecommendationView遷移:**
    -   提案カードから詳細画面へ遷移し、理由、メニュー、代替案を確認できる。
    -   ユーザーの選択は`DailyRecommendation.acceptedAction`へ保存する。
-   **AI相談:**
    -   チャットは補助導線として扱う。

## 1.4. データ要件

-   `DailyCheckIn` (Domain/Models): その日の睡眠、疲労、気分、筋肉痛、使える時間、やる気。
-   `DailyRecommendation` (Domain/Models): 今日の提案、理由、メニュー、代替案、休養アドバイス。
-   `UserGoal` (Domain/Models): 目的別提案のための目標。
-   `TrainingLog` (Domain/Models): 過去のトレーニング記録データ（進捗ウィジェットの計算に使用）。
-   `WeeklyReview` (Domain/Models): 週単位の計画遵守率、実行回数、休養日数、来週の作戦。
