---
name: ios-spec-to-implementation
description: SwiftUI + SwiftData screen specを元に、仮定を明示しつつ実装スケルトンを生成するSkill。
metadata:
  short-description: SwiftUI/SwiftData画面仕様からモデル・状態・骨子コードを出力
---

## 目的
- 箇条書きの画面仕様を受け取り、SwiftUI + SwiftDataを前提とした実装のたたき台を即時に提示する。
- データモデル案、状態、SwiftUI階層、簡易ViewModel/Store、テスト観点までを一括で出す。

## 入力テンプレート
```
タイトル: <任意>
画面仕様:
- 主要機能・表示要素（箇条書き）
- データ入出力の前提
- ナビゲーション/遷移
- 非機能要件（あれば）
制約・補足: <任意のメモ>
```

## 出力テンプレート（順番厳守）
1. **A. Assumptions（仮定）**: 不明点を最大3件の質問として列挙し、回答がなくても進めるための仮定を書く。
2. **B. Domain Model**: SwiftDataモデル案（エンティティ/属性/リレーション、軽い型注釈）。
3. **C. State & Flow**: 画面状態、遷移、エッジケース、保存/同期の扱い。
4. **D. Implementation Skeleton**: SwiftUI階層、View/Model/Repository/DIポイント、主要型の雛形コード。
5. **E. Tests**: ユニット/スナップ/状態遷移など最低限のテスト観点と例。
6. **F. Next Steps**: ユーザーが埋めるべき具体項目。

## 手順（チェックリスト）
1. 入力仕様を正規化し、欠落/曖昧な点を3件まで質問として列挙。
2. 質問があっても作業を止めず、合理的な仮定を明示して続行。
3. SwiftData + Observation前提で、DI可能なRepository/Serviceを提示。
4. 過剰なコード量を避け、ファイル分割案と主要型の雛形のみを示す。
5. ステート管理はテストしやすい構造（依存注入、プロトコル）で示す。
6. 出力テンプレートの順序を崩さない。

## 失敗時の挙動（不明点の扱い）
- 不明点は最大3件まで質問として提示し、同時に仮定を置いて進む。
- 仕様が極端に不足する場合も、推測に基づく最小限のスケルトンを返す。
- SwiftData/Observationが適用できない場合は、その理由と代替方針を短く説明する。

## スクリプトの使い方
- 仕様ファイルからSwiftスケルトンを生成する補助スクリプトを同梱。
- 例:
  ```bash
  python ./.codex/skills/ios-spec-to-implementation/scripts/generate_swift_skeleton.py \
    --spec ./specs/sample-screen.txt \
    --out ./Generated
  ```
- 出力: `Model.swift`、`ViewModel.swift`、`ContentView.swift`、`Repository.swift`、`Tests.swift` の雛形を生成（既存ファイルがある場合は上書き防止のため処理を中断）。

## リファレンス
- 本スキルが準拠するアーキテクチャ指針は `references/architecture-guideline.md` を参照。
