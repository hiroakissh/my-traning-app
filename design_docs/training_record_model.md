# トレーニング記録モデル（ドラフト）

トレーニング記録を1セッション単位で保存するためのモデル定義。日付・目的・コンディション・種目とセット詳細を一枚にまとめる。

## モデルフィールド

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| id | UUID | 任意（内部管理用） | レコード一意ID | `c8e6f0d7-8af6-43d5-8e14-8b3b4d7c3b7f` |
| date | Date (日付のみ) | 必須 | セッション日 | `2024-03-01` |
| startTime | Date (日時) | 任意 | 開始日時。分単位まで | `2024-03-01T07:30:00Z` |
| endTime | Date (日時) | 任意 | 終了日時。分単位まで | `2024-03-01T08:45:00Z` |
| sessionDurationSec | Int | 必須 | セッション全体の所要時間（秒）。タイマー計測 or 手入力で保存 | `4500` |
| purpose | Enum | 必須 | セッション目的。`refresh`（リフレッシュ）/`hypertrophy`（筋肥大）/`diet`（ダイエット）/`tune`（調整） | `hypertrophy` |
| condition | Object | 任意 | 当日の体調。少なくとも`overallCondition`を保持 | 下記参照 |
| exercises | Array\<Exercise\> | 必須（空配列可） | 実施した種目一覧 | 下記参照 |
| note | String | 任意 | セッション全体のメモ | `睡眠短め。脚に張りあり` |

### condition

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| sleepHours | Double | 任意 | 前夜の睡眠時間（時間） | `6.5` |
| sleepQuality | Int | 任意 | 睡眠の質（1–5） | `3` |
| fatigueLevel | Int | 任意 | 疲労感（1–5。高いほど疲れている） | `2` |
| mood | Int | 任意 | 気分・やる気（1–5。高いほど良い） | `4` |
| soreness | Int | 任意 | 筋肉痛レベル（1–5） | `2` |
| conditionNote | String | 任意 | 体調に関する自由記述 | `腰に少し違和感` |
| overallCondition | Int | 必須 | 体調の総合レーティング（1–5） | `4` |

### exercises（配列要素）

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| id | UUID | 任意 | 種目ごとの一意ID | `6e0b7c28-d35a-41b1-9463-73f25e97a1b9` |
| name | String | 必須 | 種目名 | `ベンチプレス` |
| bodyPart | Enum | 必須 | 主要部位（コード値）。`BodyPart`参照 | `chest` |
| category | Enum | 任意 | 種目タイプ。`strength`（筋トレ）/`cardio`（有酸素）/`mobility` など | `strength` |
| sets | Array\<ExerciseSet\> | 必須（空配列可） | セット詳細 | 下記参照 |
| note | String | 任意 | 種目に関する備考 | `肩に違和感あったので可動域控えめ` |

### sets（配列要素）

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| order | Int | 必須 | セット番号（1始まり） | `1` |
| weightKg | Double | 任意 | 使用重量（kg）。自重は0扱いまたはnull | `60.0` |
| reps | Int | 任意 | 回数 | `10` |
| durationSec | Int | 任意 | 有酸素等の時間（秒）。不要ならnull | `0` |
| rpe | Double | 任意 | 自覚的運動強度（RPE、0–10） | `7.5` |
| restSec | Int | 任意 | 直前セットからの休憩秒数 | `120` |
| setNote | String | 任意 | セット備考 | `フォーム安定` |

## 例データ（JSON想定）

```json
{
  "id": "c8e6f0d7-8af6-43d5-8e14-8b3b4d7c3b7f",
  "date": "2024-03-01",
  "startTime": "2024-03-01T07:30:00Z",
  "endTime": "2024-03-01T08:45:00Z",
  "sessionDurationSec": 4500,
  "purpose": "hypertrophy",
  "condition": {
    "overallCondition": 4,
    "sleepHours": 6.5,
    "sleepQuality": 3,
    "fatigueLevel": 2,
    "mood": 4,
    "soreness": 2,
    "conditionNote": "腰に少し違和感"
  },
  "exercises": [
    {
      "id": "6e0b7c28-d35a-41b1-9463-73f25e97a1b9",
      "name": "ベンチプレス",
      "bodyPart": "chest",
      "category": "strength",
      "sets": [
        { "order": 1, "weightKg": 60.0, "reps": 10, "rpe": 7.5, "restSec": 120, "setNote": "" },
        { "order": 2, "weightKg": 60.0, "reps": 8, "rpe": 8.0, "restSec": 150, "setNote": "" }
      ],
      "note": "肩を保護するため可動域浅め"
    },
    {
      "id": "9c0c7b7d-38bb-4fc7-a214-13a0a4d7f6be",
      "name": "エアロバイク",
      "bodyPart": "legs",
      "category": "cardio",
      "sets": [
        { "order": 1, "durationSec": 1200, "rpe": 6.0, "setNote": "心拍140前後" }
      ],
      "note": ""
    }
  ],
  "note": "睡眠短めだが集中できた"
}
```

## メモ

- `purpose`や`category`はEnumで管理しつつ、将来的な拡張も考えて未定義値も保持できる実装にしておくと扱いやすい。
- `condition`は入力負荷を考え、簡易（1–5レーティングのみ）と詳細（自由記述あり）をUIでトグルできる設計を想定。
- 自由入力が多い項目はサジェスト履歴を利用し、入力の手間と揺れを減らす。
- 週次集計（目的別総時間・総ボリューム、部位別ボリューム推移、種目別重量/回数推移）を想定し、`sessionDurationSec`と`bodyPart`、各セットの`weightKg`/`reps`から計算できる形を維持する。

### BodyPart (Enum)

| コード値 | 表示名例 |
| --- | --- |
| chest | 胸 |
| back | 背中 |
| legs | 脚 |
| shoulder | 肩 |
| arms | 腕 |
| core | 体幹 |
| fullBody | 全身 |
| other | その他 |
