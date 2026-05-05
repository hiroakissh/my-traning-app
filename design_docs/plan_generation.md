# Plan Generation

日次提案生成は画面やViewModelに直書きせず、`PlanGenerationService` に分離する。

## 構成

- `PlanGenerationService`: 日次提案生成の共通プロトコル
- `AIPlanGenerationService`: Foundation Models / LLM を使う実装
- `RuleBasedPlanGenerationService`: AI失敗時やローカル用のフォールバック実装
- `PlanGenerationCoordinator`: AIとルールベースを束ねる調整役
- `DailyRecommendationValidator`: AI出力をUIへ出す前の検証

## 生成フロー

```text
AI生成
↓
DailyRecommendationValidator
↓ 失敗
修正プロンプト付きで1回だけ再生成
↓
DailyRecommendationValidator
↓ 失敗
RuleBasedPlanGenerationServiceへフォールバック
```

無限リトライは禁止する。

## 構造化出力

AIには自由文だけを返させない。Foundation Models を使う場合は、保存・表示に使う出力を `@Generable` / `@Guide` で構造化する。

実装ルール:

- `LanguageModelSession.respond(to:)` の自由文戻り値を、そのままSwiftDataモデルやUIへ保存しない。
- 保存・表示に使う出力は `respond(to:generating:)` を使い、`@Generable` 型を通す。
- `@Guide` には件数制約、数値範囲、Markdown禁止、休養時の空メニューなどの制約を書く。
- 生成後は Domain のDTOへ変換し、Validator / Mapper を通してから利用する。
- 既存データに Markdown 風文字列が残っている場合も、表示直前に `PlanDisplayContent` のような表示用構造へ変換する。

日次提案では、必ず次の情報を構造化して返す。

- `readinessLevel`
- `recommendationType`
- `title`
- `summary`
- `reasons`
- `exercises`
- `alternatives`
- `recoveryAdvice`

制約:

- `reasons` は最低2件
- `fullWorkout` / `lightWorkout` は `exercises` を1件以上
- `rest` は `exercises` を空
- `recovery` は散歩、ストレッチ、モビリティ中心
- `alternatives` は最低2件
- 疲労、睡眠不足、強い筋肉痛がある場合は `easy` または `rest` を優先
- 休養は失敗ではなく計画の一部として扱う

長期・週間プランでは、`PlanSuggestionsOutput` としてユーザーが選べる複数候補を返す。

- `plans`: アクティブプランとして採用できる2〜3件の完全な候補
- `title`: Markdown記号を含まない短いタイトル
- `summary`: カード表示用の1文要約
- `horizon`: `longTerm` / `midTerm` / `shortTerm` / `general`
- `detail`: `項目名: 内容` の改行区切り。目標、方針、曜日ごとの作戦、休養方針、今日の最小アクションを含める。曜日は `Monday: 胸` のようにキー化する。

重要:

- Goal / Phase / Week / Today を別カードに分割しない。
- 各 `plans` の1件が、単独で `ActivePlan` として保存できる内容にする。
- ユーザーが採用した最新の `ActivePlan` は、日次提案とAI相談の入力コンテキストに渡す。

## フォールバック

AIが利用できない、または不正な出力を返した場合でも、ユーザー体験を止めない。

ユーザー向け表示:

```text
今日はAI提案を作れなかったため、チェックイン内容をもとに安全なメニューを提案しています。
```

または:

```text
今日は詳細なプラン生成に失敗しました。
代わりに、体調に合わせたシンプルなメニューを用意しました。
```

ルールベースでは、睡眠、疲労、筋肉痛、気分、使える時間からリスクスコアを作り、`rest` / `easy` / `go` を返す。

```swift
if riskScore >= 5 {
    return .rest
} else if riskScore >= 3 {
    return .easy
} else {
    return .go
}
```
