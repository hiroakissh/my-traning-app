---
name: ios-test-plan-from-spec
description: 画面仕様からiOS( SwiftUI + SwiftData )向けの最小テスト計画とケース骨子を生成するSkill。
metadata:
  short-description: SwiftUI/SwiftData画面仕様をテスト計画・ケースに落とす
---

## 目的
- 箇条書きの画面仕様をテスト観点に展開し、実装前にテスト計画を素早く用意する。
- 観点漏れを防ぐため、機能/状態/データ永続化/非機能/回帰を明示し、優先度付きで出力する。

## 入力テンプレート
```
タイトル: <画面または機能名>
画面仕様:
- 主要フロー
- 状態/エッジケース
- データ入出力・永続化前提
- 外部依存（API/HealthKit/通知 等）
非機能/制約: <パフォーマンス、アクセシビリティ、オフライン等>
```

## 出力テンプレート（順番厳守）
1. **A. Clarifications & Assumptions**: 最大3件の質問 + それに対する暫定仮定。
2. **B. Scope & Risk**: 対象範囲、除外項目、リスク/曖昧さ。
3. **C. Test Matrix**: 観点別のケース骨子（機能/状態遷移/永続化/エラー/オフライン/アクセシビリティ）、優先度と代表ケース例。
4. **D. Data & Fixtures**: 必要なサンプルデータ/SwiftDataコンテナ設定/モック方針。
5. **E. Environment & DI**: 依存注入戦略（Repository/Service）、テストダブルの置き方、並列実行の注意。
6. **F. Regression & Non-Functional**: 回帰チェック項目、パフォーマンス/アクセシビリティ/ローカライズの最低限。
7. **G. Next Steps**: 足りない情報、実装者が埋めるべき TODO。

## 手順（チェックリスト）
1. 入力仕様を正規化し、不明点を3件まで質問として列挙する。
2. 質問があっても仮定を置いて続行し、テスト観点に反映する。
3. SwiftData永続化とObservationの状態遷移を必ず観点に含める。
4. DI前提で、Repository/Serviceの差し替え方を明示する。
5. ケースは骨子レベルで簡潔に、優先度を `P0/P1/P2` で付与。
6. 出力テンプレートの順序を崩さない。

## 失敗時の挙動
- 仕様が不足している場合は、仮定と質問を提示したうえで最小限のテスト計画を返す。
- 前提が矛盾する場合は矛盾内容と影響を短く記載し、継続する。

## スクリプトの使い方
- 仕様テキストからテスト計画の雛形Markdownを生成する補助スクリプトを同梱。
- 例:
  ```bash
  python ./.codex/skills/ios-test-plan-from-spec/scripts/generate_test_plan.py \
    --spec ./specs/sample-screen.txt \
    --out ./Generated/test-plan.md
  ```
- 既存ファイルがある場合は上書きを避けるためエラーを返す。

## リファレンス
- 本スキルが準拠するテスト指針は `references/testing-guideline.md` を参照。
