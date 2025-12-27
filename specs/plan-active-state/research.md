# プランアクティブ状態管理 リサーチメモ

- 画面仕様: `design_docs/screen_specifications/04_planning.md`では長期/中期/短期のセクションと「プランを再生成」ボタンが定義されている。アクティブプラン表示と候補切替が必要。
- アーキテクチャ: `design_docs/architecture_and_design_guidelines.md`でSwiftUI + SwiftDataのシンプルなアプローチを推奨。`@Query`と`ModelContext`を直接利用する。
- 現状の`AIWorkoutPlanner`は文字列を保持するのみで構造化がない。モック応答はMarkdown形式の見出しを含むため、ヘッダーベースのセクション切り出しが可能。
- 永続化: SwiftDataの`@Model`で新規`ActivePlan`を定義し、アクティブプラン履歴は保持しつつ最新を`adoptedAt`で判定する方針とする。
