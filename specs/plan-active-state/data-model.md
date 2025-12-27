# プランアクティブ状態管理 データモデル

## PlanHorizon (Enum)
| ケース | 用途 | 表示例 |
| --- | --- | --- |
| longTerm | 3ヶ月など長期プラン | 「長期プラン」 |
| midTerm | 1ヶ月など中期プラン | 「中期プラン」 |
| shortTerm | 1週間など短期プラン | 「短期プラン」 |
| general | セクション判別不可時の汎用プラン | 「プラン」 |

## PlanSuggestion (Struct)
| フィールド | 型 | 必須 | 内容 |
| --- | --- | --- | --- |
| id | UUID | ✅ | 表示・採用用の一意ID |
| horizon | PlanHorizon | ✅ | セクション種別 |
| title | String | ✅ | 見出し（AI応答のセクション名） |
| summary | String | ✅ | セクション本文の先頭行または見出し |
| detail | String | ✅ | セクション本文全体 |
| rawText | String | ✅ | 元のAI応答全文 |
| sourcePrompt | String | ✅ | 生成に使用したプロンプト |
| createdAt | Date | ✅ | 応答受信日時 |

## ActivePlan (@Model)
| フィールド | 型 | 必須 | 内容 |
| --- | --- | --- | --- |
| id | UUID | ✅ | 一意ID |
| horizonRaw | String | ✅ | 保存用のhorizon値（PlanHorizon.rawValue） |
| title | String | ✅ | 表示タイトル |
| summary | String | ✅ | カード表示用概要 |
| detail | String | ✅ | 詳細本文 |
| sourcePrompt | String | ✅ | 生成プロンプト |
| adoptedAt | Date | ✅ | 採用日時 |

### 挙動
- 最新のアクティブプランは`adoptedAt`が最も新しいものを採用する。
- 履歴は削除せず保持するが、画面表示は最新1件を基本とする。
