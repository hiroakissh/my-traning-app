# my-traning-app

## 概要

my-traning-app は、今日の体調・気分・目的に合わせて、運動する・軽く動く・休むを提案するAIコンディションコーチアプリです。
単なるトレーニング記録ではなく、ユーザーが継続できるように、毎日の意思決定と計画調整を支援します。

## 主な機能

### 今日の処方箋

*   Daily Check-Inで睡眠、疲労、気分、筋肉痛、使える時間、やる気を数タップで入力。
*   チェックイン内容、目的、過去の記録から `go` / `easy` / `rest` の状態判定を行う。
*   ホーム最上部に TodayRecommendationCard を表示し、今日の提案、理由、メニュー、代替案、休養選択肢を提示。

### AIによる構造化提案

*   Foundation Modelsの `@Generable` / `@Guide` を使い、`DailyRecommendationOutput` 相当の構造化出力を生成。
*   AIが利用できない環境では、同じデータ構造にルールベース提案を流し込む。
*   提案は必ず理由、推奨メニュー、代替案、回復アドバイスを持つ。

### 休養を含めた計画遵守

*   `RecommendationType.rest` / `recovery` と `ActivityResult.rested` / `recoveryCompleted` を通常の成功行動として扱う。
*   スキップと休養を分け、休んでも戻れるUXを優先。
*   連続記録日数よりも、今週の実行率、休養を含めた計画遵守率、週単位の継続を重視。

### 目的別モード

*   `UserGoal` / `GoalType` により、race / strength / diet / health / mentalRecovery / habit で提案方針を切り替え可能。
*   筋力アップでは漸進性、ダイエットでは継続可能性、メンタル回復では気分改善、習慣化では5分メニューを優先。

### トレーニング記録と履歴管理

*   種目、重量、回数、セット数などの詳細なトレーニング記録。
*   過去のトレーニング履歴の閲覧と分析。

### AI相談

*   AIチャットはメイン導線ではなく、迷ったときの補助機能として扱う。
*   ホームの中心は「チェックイン → 今日の処方箋 → 選択 → 記録」。

### ヘルスケア連携

*   **トレーニングデータ:** Apple Watchとの連携によるワークアウト中のデータ（心拍数、消費カロリーなど）を自動で記録。
*   **身体データ:** 体重、体脂肪率、除脂肪体重などの身体データをHealthKitから定期的に同期。目標達成度の評価や、より正確なプランニングに活用します。

### Apple Watch連携

*   Apple Watch上でのトレーニングデータ入力。
*   ランニングやその他の運動計測機能。

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
