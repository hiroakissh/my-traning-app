# TrainingLogモデル（ドラフト）

1回のトレーニングセッション（TrainingLog）を保存するためのモデル定義。日付・目的・コンディション・種目（TrainingExercise）とセット（TrainingSet）を一枚にまとめる。

## モデルフィールド

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| id | UUID | 必須 | レコード一意ID（外部連携も考慮し常に保持） | `c8e6f0d7-8af6-43d5-8e14-8b3b4d7c3b7f` |
| date | Date (日付のみ) | 必須 | セッション日 | `2024-03-01` |
| startTime | Date (日時) | 任意 | 開始日時。分単位まで | `2024-03-01T07:30:00Z` |
| endTime | Date (日時) | 任意 | 終了日時。分単位まで | `2024-03-01T08:45:00Z` |
| sessionDurationSec | Int | 必須 | セッション全体の所要時間（秒）。タイマー計測 or 手入力で保存 | `4500` |
| purpose | Enum | 必須 | セッション目的。`refresh`（リフレッシュ）/`hypertrophy`（筋肥大）/`diet`（ダイエット）/`tune`（調整） | `hypertrophy` |
| source | Enum | 必須 | ログの作成元。`timer`/`manual`/`imported` | `timer` |
| condition | Object | 任意 | 当日の体調。少なくとも`overallCondition`を保持 | 下記参照 |
| exercises | Array\<TrainingExercise\> | 必須（空配列可） | 実施した種目一覧 | 下記参照 |
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

### TrainingExercise（配列要素）

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| id | UUID | 必須 | 種目ごとの一意ID | `6e0b7c28-d35a-41b1-9463-73f25e97a1b9` |
| name | String | 必須 | 種目名 | `ベンチプレス` |
| bodyPart | Enum | 必須 | 主要部位（コード値）。`BodyPart`参照 | `chest` |
| category | Enum | 任意 | 種目タイプ。`strength`（筋トレ）/`cardio`（有酸素）/`mobility` など | `strength` |
| sets | Array\<TrainingSet\> | 必須（空配列可） | セット詳細 | 下記参照 |
| note | String | 任意 | 種目に関する備考 | `肩に違和感あったので可動域控えめ` |

### TrainingSet（配列要素）

| フィールド | 型 | 必須 | 内容 | 例 |
| --- | --- | --- | --- | --- |
| id | UUID | 必須 | セットごとの一意ID | `f1ad9f9a-3a9c-4b1e-9b6b-8c5e7d5d9a7f` |
| order | Int | 必須 | セット番号（1始まり） | `1` |
| weightKg | Double | 任意 | 使用重量（kg）。未記録はnull。自重は`isBodyweight=true`で表現 | `60.0` |
| reps | Int | 任意 | 回数 | `10` |
| durationSec | Int | 任意 | 有酸素等の時間（秒）。未記録はnull（0は使用しない） | `1200` |
| rpe | Double | 任意 | 自覚的運動強度（RPE、0–10） | `7.5` |
| restSec | Int | 任意 | 直前セットからの休憩秒数 | `120` |
| setNote | String | 任意 | セット備考 | `フォーム安定` |
| isWarmup | Bool | 任意 | ウォームアップセットかどうか（集計除外の判断に使用） | `false` |
| isBodyweight | Bool | 任意 | 自重セットかどうか。trueなら`weightKg`はnullで扱う | `false` |

## 例データ（JSON想定）

```json
{
  "id": "c8e6f0d7-8af6-43d5-8e14-8b3b4d7c3b7f",
  "date": "2024-03-01",
  "startTime": "2024-03-01T07:30:00Z",
  "endTime": "2024-03-01T08:45:00Z",
  "sessionDurationSec": 4500,
  "purpose": "hypertrophy",
  "source": "timer",
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
        { "id": "f1ad9f9a-3a9c-4b1e-9b6b-8c5e7d5d9a7f", "order": 1, "weightKg": 60.0, "reps": 10, "rpe": 7.5, "restSec": 120, "setNote": "", "isWarmup": false, "isBodyweight": false },
        { "id": "b35c8d6e-3e6a-4e80-8f5e-8a6b3b7c9d1e", "order": 2, "weightKg": 60.0, "reps": 8, "rpe": 8.0, "restSec": 150, "setNote": "", "isWarmup": false, "isBodyweight": false }
      ],
      "note": "肩を保護するため可動域浅め"
    },
    {
      "id": "9c0c7b7d-38bb-4fc7-a214-13a0a4d7f6be",
      "name": "エアロバイク",
      "bodyPart": "legs",
      "category": "cardio",
      "sets": [
        { "id": "e2c0b7b7-13a0-4d7f-6be9-c0c7b7d38bb4", "order": 1, "durationSec": 1200, "rpe": 6.0, "setNote": "心拍140前後", "isWarmup": false, "isBodyweight": true }
      ],
      "note": ""
    }
  ],
  "note": "睡眠短めだが集中できた"
}
```

## メモ

- `purpose`や`category`はEnumで管理しつつ、将来的な拡張も考えて未定義値も保持できる実装にしておくと扱いやすい。
- `condition`は入力負荷を考え、簡易（1–5レーティングのみ）と詳細（自由記述あり）をUIでトグルできる設計を想定。`overallCondition`は「その日の体感コンディションを1–5で自己評価」し、週次グラフで`totalVolume`/`sessionDurationSec`と並べて可視化する前提。
- 自由入力が多い項目はサジェスト履歴を利用し、入力の手間と揺れを減らす。
- 週次集計（目的別総時間・総ボリューム、部位別ボリューム推移、種目別重量/回数推移）を想定し、`sessionDurationSec`と`bodyPart`、各セットの`weightKg`/`reps`から計算できる形を維持する。
- sourceを保持することで、タイマー起点のみ/手入力のみ/インポートのみの分析・フィルタが可能。
- ウォームアップは`isWarmup=true`でセット内に保持し、集計時に除外できるようにする。
- nullは「記録していない」を意味し、重量・時間で0は使用しない。自重は`isBodyweight=true`で表現し、`weightKg`はnullとする。
- 同期・エクスポートを見据え、TrainingExercise/TrainingSetにもUUIDを必須で付与し安定同一性を担保する。

### LogSource (Enum)

| コード値 | 用途 |
| --- | --- |
| timer | タイマー起点で記録。start/endは埋める、durationはタイマー値 |
| manual | 手入力で記録。duration必須、start/endは任意 |
| imported | 外部連携で取り込み。duration必須、start/endはソース依存 |

### 運用ルール（sets）

- category = strength: `weightKg`と`reps`を基本入力。`durationSec`は原則使用しない。フォーム崩れ/ウォームアップは`isWarmup=true`で記録。
- category = cardio: `durationSec`を基本入力。`weightKg`/`reps`はnullで問題なし。ペース・距離は別フィールド検討時に追加。
- mobility/other: `durationSec`を基本入力とし、必要に応じて`setNote`で補足。


### V1でUIから入力させる項目

| モデル | フィールド | UI入力 | 備考 |
| --- | --- | --- | --- |
| TrainingLog | date | 必須 | 日付ピッカー |
| TrainingLog | sessionDurationSec | 必須 | タイマー or 手入力 |
| TrainingLog | purpose | 必須 | セレクト |
| TrainingLog | source | 必須 | セレクト（timer/manual/imported） |
| TrainingLog | condition.overallCondition | 任意 | スライダー1–5 |
| TrainingExercise | name | 必須 | サジェスト付きテキスト |
| TrainingExercise | bodyPart | 必須 | Enum選択 |
| TrainingExercise | category | 必須 | Enum選択（strength/cardio/etc） |
| TrainingSet | weightKg | strengthのみ必須 | 数値入力 |
| TrainingSet | reps | strengthのみ必須 | 数値入力 |
| TrainingSet | durationSec | cardio/mobilityのみ必須 | 秒入力 |
| TrainingSet | rpe | 任意 | スライダー or 数値 |
| TrainingSet | restSec | 任意 | 数値（秒） |
| TrainingSet | isWarmup | 任意 | チェックボックス。集計除外用 |
| TrainingSet | isBodyweight | 任意 | 自重セットならON（weightKgはnull） |

### V1 入力フロー（ラフ）

- 1画面目: `date`/`purpose`/`overallCondition`/`sessionDurationSec`/`source`
- 2画面目: 種目一覧の追加・編集（`name`/`bodyPart`/`category`）
- 3画面目: 種目別のセット編集（`weightKg`/`reps`/`durationSec`/`rpe`/`restSec`/`isWarmup`/`isBodyweight`）

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
