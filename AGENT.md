# my-training-app AGENT ハンドブック

このリポジトリに貢献するAI／自動化エージェント向けの最新ガイドラインです。仕様駆動開発（Specification-Driven Development）を前提とします。

## 1. プロジェクト目的と範囲
- アプリ種別: SwiftUIベースのパーソナルトレーニング記録＆AIプラン生成アプリ。
- 対応プラットフォーム: iOS（iPhone + Apple Watch）、任意でウィジェット対応。
- 差別化要素: Foundation Modelによるプランニング、HealthKit連携、進捗の可視化。
- 主要参照資料: `my-training-app/templates/specification.md`、`design_docs/architecture_and_design_guidelines.md`、`design_docs/user_flow.md`。

## 2. 仕様駆動ワークフロー
以下のフェーズを順番に実施し、ゲートを飛ばさないこと。
1. **仕様書作成 (`/specs/.../spec.md`)**  
   - `my-training-app/templates/spec-template.md` をベースにする。  
   - ユーザーシナリオ・受入条件・曖昧な箇所を `[NEEDS CLARIFICATION]` で明示。
2. **計画策定 (`plan.md`, `/plan` コマンド範囲)**  
   - `my-training-app/templates/plan-template.md` を使い、実行フロー・技術コンテキスト・憲法チェック・設計ドキュメント（research, data-model, contracts, quickstart）を整備。  
   - 憲法チェックは Phase1 前後で2回実施し、逸脱は記録する。
3. **タスク生成 (`tasks.md`)**  
   - `/tasks` コマンドが Phase1 の成果物をもとに、`my-training-app/templates/tasks-template.md` を用いてテスト先行の順序付きタスクを作成。
4. **実装**  
   - Red-Green-Refactor 順に実装し、実装前にテストが必ず失敗する状態を作る。  
   - `my-training-app/scripts/update-agent-context.sh` が計画に含まれる場合のみ、新しい技術情報でエージェントファイルを更新。
5. **検証**  
   - 契約テスト・結合テスト・UIテストすべてを実行し、quickstart手順も確認。  
   - 仕様書の受入シナリオを満たしているか検証。

## 3. 基本ルールとゲートキーパー
- **シンプル最優先**: アクティブなプロジェクト（api/cli/tests）は最大3つまで。リポジトリPatternやUoWなど複雑なパターンは、Complexity Trackingに根拠を記載しない限り禁止。
- **ライブラリ遵守**: 機能は可能な限りモジュール化し、CLI公開が適用可能ならコマンドと目的を記録。
- **TDD（絶対遵守）**: 実装前に契約テスト／結合テストを書く。可能な限り実サービス（HealthKit、Foundation Model Client）を使用し、モック依存を避ける。
- **可観測性**: アプリ・バックエンド（導入時）・AI連携のログを構造化し、横断的に追跡可能にする。
- **バージョニング**: `MAJOR.MINOR.BUILD` 形式を採用し、変更ごとに BUILD を増分。破壊的変更には移行計画を立てる。
- **憲法参照**: 原則の調整時は `memory/constitution.md` を参照し、文書化された承認がない限り改訂しない。

## 4. アーキテクチャと技術スタンス
- **UI**: SwiftUI View を基本とし、外部MVVMラッパーは禁止。`@State`、`@EnvironmentObject`、`@Query` を活用する。
- **Domain**: SwiftData のモデルとサービスがビジネスロジック（例: AIWorkoutPlanner）を保持。
- **Infrastructure**: HealthKit、FoundationModel Client、永続化設定は専用モジュールに集約。
- **AI連携**: Foundation Model へのプロンプトには、ユーザー目標・履歴・HealthKit入力を含め、編集可能なプランを返す。
- **デバイス間同期**: Apple Watch コンパニオンアプリによるワークアウト記録と iPhone への自動同期フローを維持。
- **テスト**: AIプランナーのユニットテスト、新規APIの契約テスト、主要フローのSwiftUI UIテストを最低限カバー。

## 5. リポジトリ構成と資産
- 仕様書は `specs/[feature]/` に配置し、各機能ごとに `research.md`、`data-model.md`、`quickstart.md`、`contracts/`、`tasks.md` を保持。
- 自動化向けテンプレートは `my-training-app/templates/` にあり、新規ドキュメント作成時以外はプレースホルダーを変更しない。
- アプリケーションコードは `design_docs/architecture_and_design_guidelines.md` に定義された構造に従う：
  - `Application/`、`Domain/`、`Presentation/`、`Infrastructure/`、`Resources/`、`Utilities/`、`MyTrainingAppWidget/`、各種テストターゲット。
- 上位設計・UX関連ドキュメントは `design_docs/`（アーキテクチャ、ユーザーフロー、画面仕様）に配置。

## 6. コーディング & ドキュメント標準
- 使用言語: Swift 5.x、インデントはスペース4つ。命名は Swift API Design Guidelines に従い、型は `UpperCamelCase`、メンバは `lowerCamelCase`、Bool は `is/has/should` 接頭辞を使う。
- 公開APIは Swift-DocC (`///`) で記述し、非自明なロジックにだけ簡潔なコメントを追加。
- SwiftUI View はコンポジションを重視し、再利用可能なコンポーネントに切り出し、`body` の肥大化を避ける。
- 必要最小限のモジュールのみ `import` し、アクセス制御（`private`、`internal`）を適切に設定。
- `AGENT.md` は概ね150行以内を維持し、必要に応じて手動追記は指定マーカー内に挿入。

## 7. ツールとコマンド
- 主なコマンド: `swift build`、`swift test`、SwiftUI Previews、UIテスト用の `xcodebuild test`。
- 新技術やライブラリを導入した場合は `my-training-app/scripts/update-agent-context.sh` でエージェントコンテキストを更新。
- AIや外部サービスを統合する際は、プロンプトや連携手順を `design_docs/` または機能別のリサーチ文書に記録。

## 8. コントリビューションチェックリスト
- 仕様書が承認済みで `[NEEDS CLARIFICATION]` が残っていない。
- 計画書に憲法チェック結果が反映されている。
- 実装前にリサーチ／設計成果物（research, data-model, contracts, quickstart）が完成している。
- 実装前にテストを作成し、失敗を確認済み。
- 実装がアーキテクチャ境界を尊重している。
- テスト・quickstart の実行結果など検証記録が残っている。

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
