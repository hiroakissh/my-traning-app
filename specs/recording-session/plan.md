# 実装計画: 記録画面のHealthKit連携強化

## 実行フロー
1. 仕様確認: `design_docs/screen_specifications/02_recording.md` と本計画を同期。
2. ドメイン設計: TrainingLog/HealthDataSnapshot/CardioMetrics を定義。
3. インフラ設計: HealthDataProvidingプロトコルとモック実装を用意。
4. UI実装: RecordingViewで日付選択、種目選択、セット入力、ランニング入力、ヘルスデータ表示、保存ボタンを提供。
5. テスト: 新規モデルとユーティリティのユニットテストを作成・実行（モックデータのみ）。

## 技術コンテキスト
- SwiftUIベース、ViewModelレス方針。状態は`@State`で保持し、モデルはDomain層に配置。
- HealthKit実機依存のため、`HealthDataProviding`をプロトコル化してモックを注入。
- SwiftDataは未接続だが、将来拡張できるよう`TrainingLog`をモデル化。

## 憲法チェック（事前）
- **シンプル最優先**: ビューの状態とドメインモデルを最小限に保つ。
- **TDD遵守**: モデル計算（ペース計算、ヘルスデータ合算）のテストを先に作成。
- **可観測性**: データ取得の状態をUIで確認できるようサマリーを表示。

## 設計ドキュメント
- research: HealthKitで取得可能なサンプルと制約を整理。
- data-model: TrainingLog/HealthDataSnapshot/CardioMetricsのフィールド定義。
- contracts: 本フェーズではモックのため未作成。
- quickstart: 記録開始～保存までの操作手順を記載。

## 実行タスク（概要）
- テスト作成→モデル/インフラ実装→UI強化→ドキュメント更新の順で進行。

## 憲法チェック（事後予定）
- テストが新機能をカバーし、仕様の受入条件を満たすことを確認。
