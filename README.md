# my-traning-app

my-traning-app は、今日の体調・気分・目的に合わせて、
「運動する」「軽く動く」「休む」を提案するAIコンディションコーチアプリです。

毎日完璧にトレーニングするためのアプリではありません。
疲れている日は休む。
時間がない日は10分だけ動く。
余裕がある日は追い込む。
その日の自分に合わせて、無理なく戻ってこられる運動習慣を支援します。

## Core Experience

1. 今日の状態をチェックインする
2. AIまたはルールベースが今日の状態を判定する
3. 今日の処方箋を提案する
4. ユーザーは「通常」「短縮」「回復」「休養」から選ぶ
5. 実行結果が次回の提案に反映される

## 主な機能

### 今日の処方箋

*   Daily Check-Inで睡眠、疲労、気分、筋肉痛、使える時間、やる気を数タップで入力。
*   チェックイン内容、目的、過去の記録から `go` / `easy` / `rest` の状態判定を行う。
*   ホーム最上部に TodayRecommendationCard を表示し、今日の提案、理由、メニュー、代替案、休養選択肢を提示。

### AIによる構造化提案

*   Foundation Modelsの `@Generable` / `@Guide` を使い、`DailyRecommendationOutput` 相当の構造化出力を生成。
*   `PlanGenerationService` / `PlanGenerationCoordinator` で、生成・検証・再生成・フォールバックを画面から分離。
*   `DailyRecommendationValidator` により、AI出力をそのままUIへ出さず検証する。
*   AIが利用できない、または不正な提案を返した場合でも、同じデータ構造にルールベース提案を流し込む。
*   提案は必ず理由、推奨メニュー、代替案、回復アドバイスを持つ。

### 休養を含めた計画遵守

*   `RecommendationType.rest` / `recovery` と `ActivityResult.rested` / `recoveryCompleted` を通常の成功行動として扱う。
*   スキップと休養を分け、休んでも戻れるUXを優先。
*   連続記録日数よりも、今週の実行率、休養を含めた計画遵守率、週単位の継続を重視。

### 目的別モード

*   `UserGoal` / `GoalType` により、race / strength / diet / health / mentalRecovery / habit で提案方針を切り替え可能。
*   筋力アップでは漸進性、ダイエットでは継続可能性、メンタル回復では気分改善、習慣化では5分メニューを優先。

### トレーニング記録と履歴管理

*   `DailyRecommendation` から `WorkoutSession` を開始し、予定メニューを最小操作で消化する。
*   主操作はセット完了、重量・回数の調整、RPE入力、セット/種目スキップ、セッション終了。
*   終了時に `TrainingLog` へ変換し、予定通り・短縮・スキップ・RPE・予定との差分を保存する。
*   過去のトレーニング履歴の閲覧と分析。

### AI相談

*   AIチャットはメイン導線ではなく、迷ったときの補助機能として扱う。
*   ホームの中心は「チェックイン → 今日の処方箋 → 選択 → 記録」。

### ヘルスケア連携

*   **トレーニングデータ:** Apple Watchとの連携によるワークアウト中のデータ（心拍数、消費カロリーなど）を自動で記録。
*   **身体データ:** 体重、体脂肪率、除脂肪体重などの身体データをHealthKitから定期的に同期。目標達成度の評価や、より正確なプランニングに活用します。

### Apple Watch連携

*   Apple Watchは「最小操作端末」として扱う。
*   今日のメニュー確認、ワークアウト開始、現在の種目・セット確認、セット完了、休憩タイマー、RPE簡易入力、セッション終了を中心にする。
*   種目名編集、重量・回数の細かい編集、長文メモ、AIとの長文チャットはiPhone側に寄せる。
*   WatchのRPEは `easy -> 5`、`normal -> 7`、`hard -> 9` の3段階から始める。

### Widget機能

*   ホーム画面のウィジェットで、目標までの進捗やトレーニング継続状況を可視化。
*   ユーザーのモチベーションを継続的に高めるための情報を表示。

### 拡張機能（今後の展望）

*   栄養データの記録と管理。
*   食事内容の記録と分析。

## 使用技術とアーキテクチャ

*   **開発言語:** Swift
*   **UIフレームワーク:** SwiftUI
*   **データ永続化:** SwiftData
*   **AI機能:** Foundation Models (`@Generable` / `@Guide` structured output)
*   **デバイス連携:** HealthKit, CoreMotion
*   **アーキテクチャ:**
    *   個人開発の保守性を考慮した、シンプルなViewModelレスアーキテクチャを採用。
    *   クリーンアーキテクチャに厳密には従わず、シンプルで理解しやすいコードベースを目指す。

## CLIビルド・起動

ローカルのBuildアクションには以下のスクリプトを接続できます。

```bash
scripts/build_and_launch_ios.sh
```

既定値:

*   Scheme: `my-traning-app`
*   Simulator: `iPhone 17`
*   Bundle ID: `com.hiroakiapp.my-traning-app`
*   Screenshot: `build/ios-launch/my-traning-app-launch.png`

環境変数で上書きできます。

```bash
SIMULATOR_NAME="iPad Pro 13-inch (M5)" scripts/build_and_launch_ios.sh
```
