# プロジェクト設計ドキュメント

## 1. プロジェクト概要

AIがユーザーの目標に合わせたトレーニングプランを提案し、日々のトレーニングを記録・サポートする自分専用のトレーニング記録アプリ。ヘルスケアデータやApple Watchとの連携により、ユーザーの状況に応じた最適なプランニングと、継続的なモチベーション維持を支援する。

## 2. アーキテクチャ

個人開発における保守性と開発スピードを重視し、ViewModelレスのシンプルなアーキテクチャを採用する。

### 基本方針

-   **ViewModelレス:** SwiftUIの標準機能（`@State`, `@StateObject`, `@EnvironmentObject`, `@Query`など）を最大限に活用し、ViewとModel（ビジネスロジック）を直接つなぐ。
-   **データフロー:** Viewからのユーザーアクションは、ビジネスロジックを持つモデルオブジェクトを直接操作する。SwiftDataがデータの変更を検知し、関連するViewを自動的に更新する。
    -   `View` -> `Action` -> `Model (SwiftData)` -> `View (自動更新)`
-   **関心の分離:**
    -   **View:** UIの構造とレイアウトに責任を持つ。状態の保持は最小限にする。
    -   **Domain/Model:** アプリケーションのビジネスロジックとデータ（SwiftDataモデル）に責任を持つ。
    -   **Infrastructure:** HealthKit, Foundation Model APIなどの外部サービスとの連携に責任を持つ。

### レイヤー間の連携

-   **Presentation <-> Domain:**
    -   `Presentation`層（SwiftUI View）は、`@Query`プロパティラッパーを通じて`Domain`層のモデル（SwiftDataオブジェクト）を直接取得し、UIに表示します。
    -   ユーザーのアクション（ボタンタップなど）に応じて、Viewは`Domain`層のモデルオブジェクトのメソッドを直接呼び出すか、`Domain/Services`に定義されたビジネスクラスを介して、データの更新やビジネスロジックの実行を依頼します。
    -   `Domain`層のデータが変更されると、SwiftDataが自動的に変更を検知し、関連する`Presentation`層のViewを更新します。

-   **Infrastructure <-> Domain:**
    -   `Infrastructure`層は、外部サービス（HealthKit, AIモデルなど）との通信を担当します。
    -   外部から取得したデータは、`Domain`層のモデルオブジェクトに変換（マッピング）されてから、アプリケーション内で利用されます。
    -   逆に、`Domain`層のデータを外部サービスに送信する際も、`Infrastructure`層がその変換と通信の役割を担います。これにより、`Domain`層は外部サービスの実装詳細から隔離されます。

-   **Foundation Models:**
    -   保存・表示・ドメイン判断に使うAI出力は、`@Generable` / `@Guide` による構造化出力を基本とします。
    -   `LanguageModelSession.respond(to:)` の自由文は、永続化されるプランや推薦の主契約として使わず、`respond(to:generating:)` でDTOへ変換します。
    -   生成後はValidatorまたはMapperを通し、Markdown風テキストをそのままUIへ表示しません。

## 3. 設計指針

-   **シンプルさの追求:** 複雑な抽象化や過度な設計パターンを避け、SwiftUIとSwiftDataの思想に沿った、シンプルで宣言的なコードを記述する。
-   **プレビュー駆動開発:** UIコンポーネントは、`#Preview`マクロを積極的に活用し、独立して開発・テストできるようにする。様々な状態をプレビューで表現することで、堅牢なUIを構築する。
-   **再利用性:** 汎用的なUIコンポーネントやロジックは、独立したファイルに切り出し、再利用性を高める。

## 4. コード生成ルール (Gemini向け)

Geminiがコードを生成・編集する際は、以下のルールに厳密に従うこと。

### 4.1. 命名規則

Swift API Design Guidelinesに準拠する。

-   **型 (Class, Struct, Enum, Protocol):** `UpperCamelCase`
    -   例: `TrainingLogView`, `WorkoutPlan`
-   **メソッド、プロパティ、変数:** `lowerCamelCase`
    -   例: `func fetchTrainingData()`, `var workoutName: String`
-   **真偽値 (Bool):** `is`, `has`, `should` などの接頭辞を使用する。
    -   例: `var isCompleted: Bool`, `var hasAppleWatch: Bool`

### 4.2. コーディングスタイル

-   **インデント:** スペース4つ。
-   **`self`の利用:** クロージャ内や、プロパティ名と引数名が衝突する場合など、コンパイラが要求する場合にのみ明示的に使用する。
-   **アクセス制御:** `private`や`internal`を適切に使用し、不要な公開を避ける。Viewの`body`内でしか使わないヘルパーメソッドやプロパティは`private`にする。
-   **import:** モジュール全体ではなく、必要な機能のみを`import`する。（例：`import SwiftUI`）

### 4.3. ドキュメンテーション

-   **PublicなAPI:** Swift-DocC形式（`///`）で、機能の概要、引数、戻り値を記述する。
-   **複雑なロジック:** `//`を用いて、実装の意図や理由を簡潔に説明する。

### 4.4. SwiftUI

-   **Viewの分割:** `body`プロパティが複雑になる場合は、`private`なComputed Propertyやメソッド、または独立したViewコンポーネントに分割する。
-   **`some View`:** Viewを返す関数の戻り値は、具体的な型ではなく`some View`を使用し、実装の詳細を隠蔽する。
-   **プレビュー:** 新しいViewを作成する際は、必ず`#Preview`ブロックを記述し、基本的な表示を確認できるようにする。複数の状態（例：ライトモード、ダークモード、データが空の場合）をプレビューすると尚良い。

```swift
#Preview("Default") {
    MyCustomView()
}

#Preview("Dark Mode") {
    MyCustomView()
        .preferredColorScheme(.dark)
}
```

### 4.5. SwiftData

-   **モデル定義:** `@Model`マクロを使用してモデルクラスを定義する。
-   **UIスレッド:** メインスレッド（UIスレッド）で、時間のかかるデータクエリや更新処理を行わない。必要な場合は、`ModelContext`の`perform`メソッドやバックグラウンドタスクを利用する。
-   **リレーションシップ:** モデル間の関連は、SwiftDataのリレーションシップ機能（`@Relationship`）を活用する。

### 4.6. エラーハンドリング

-   **明確なエラー処理:** `Result`型や`do-catch`文を用いて、エラーが発生しうる処理（特にネットワーク通信やファイルI/O）を適切にハンドリングする。ユーザーにエラー内容をフィードバックする方法も考慮する。

### 4.7. テスト

-   **テストの責務:** `Domain`層のサービスクラスなど、ビジネスロジックを含むコードには、原則としてユニットテストを記述し、品質を担保する。
-   **ルールの徹底:** ビジネスロジックを新規に実装、または修正・リファクタリングする場合、以下の対応を必須とする。
    1.  **新規実装時:** 対応するテストケースを必ず作成する。
    2.  **修正・リファクタリング時:** 既存のテストを実行し、意図しない動作破壊（リグレッション）がないかを確認する。必要に応じて、変更内容に合わせてテストケースも修正する。
-   **設計:** テスト対象のクラスが外部のクラスに依存している場合、DI（依存性注入）とプロトコルを活用し、テスト時にはモックオブジェクトを注入できるように設計する。これにより、テスト対象の責務のみを独立して検証できる。

## 5. ディレクトリ構成

プロジェクトの保守性と拡張性を高めるため、以下のディレクトリ構成を基準とします。各レイヤーは明確に分離され、それぞれの責務に集中します。

```
/
├── MyTrainingApp.xcodeproj
├── MyTrainingApp/
│   ├── Application/
│   │   ├── MyTrainingApp.swift       # Appのメインエントリポイント
│   │   └── AppEnvironment.swift      # EnvironmentObjectなど全体で共有する状態
│   │
│   ├── Domain/
│   │   ├── Models/                   # SwiftDataのモデル定義
│   │   │   ├── Workout.swift
│   │   │   └── Exercise.swift
│   │   ├── Services/                 # ビジネスロジック
│   │   │   └── AIWorkoutPlanner.swift
│   │   └── Repositories/             # データ操作のインターフェース（必要に応じて）
│   │
│   ├── Presentation/
│   │   ├── Views/                    # 各画面のトップレベルView
│   │   │   ├── HomeView.swift
│   │   │   └── WorkoutDetailView.swift
│   │   ├── Components/               # 再利用可能な共通UIコンポーネント
│   │   │   ├── ChartView.swift
│   │   │   └── PrimaryButton.swift
│   │   └── Extensions/               # Viewに関する拡張
│   │       └── Color+Extension.swift
│   │
│   ├── Infrastructure/
│   │   ├── HealthKit/
│   │   │   └── HealthKitManager.swift
│   │   ├── FoundationModel/
│   │   │   └── FoundationModelClient.swift
│   │   └── Persistence/              # SwiftDataの永続化設定など
│   │       └── SwiftDataStack.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets           # 画像、アイコン、カラーセット
│   │   └── Strings/                  # ローカライズファイル
│   │
│   └── Utilities/
│       ├── Extensions/               # Foundationなど汎用的な拡張
│       │   └── Date+Extension.swift
│       └── Helpers/                  # 汎用ヘルパー
│
├── MyTrainingAppTests/               # ユニットテスト
│   └── Domain/
│       └── AIWorkoutPlannerTests.swift
│
├── MyTrainingAppUITests/             # UIテスト
│
├── MyTrainingAppWidget/              # Widgetターゲット
│   ├── MyTrainingAppWidget.swift
│   └── MyTrainingAppWidgetBundle.swift
│
├── design_docs/
│   └── architecture_and_design_guidelines.md
│
└── README.md
```

### 各ディレクトリの責務

-   **`Application`**: アプリケーションの起動と全体的な環境設定を担当します。`@main`を持つ`App`構造体や、アプリ全体で共有される`EnvironmentObject`などを配置します。

-   **`Domain`**: アプリケーションの心臓部です。ビジネスルール、データモデル、そして主要なビジネスロジックが含まれます。このレイヤーは、UIや外部のデータソースから独立しています。
    -   `Models`: SwiftDataで永続化されるデータモデル（例: `Workout`, `Exercise`）を定義します。
    -   `Services`: アプリケーション固有のビジネスロジック（例: AIによるワークアウトプラン生成）を実装します。

-   **`Presentation`**: UI（ユーザーインターフェース）に関連するすべてのコンポーネントを配置します。
    -   `Views`: アプリケーションの各画面を構成するSwiftUIのViewです。
    -   `Components`: 複数のViewで再利用される、より小さなUI部品（ボタン、チャートなど）です。
    -   `Extensions`: `Color`や`Font`など、UIに特化した拡張を配置します。

-   **`Infrastructure`**: 外部の世界とのやり取りを担当します。具体的な技術やライブラリへの依存は、このレイヤーに閉じ込めます。
    -   `HealthKit`: HealthKitとのデータ連携を行います。
    -   `FoundationModel`: AIモデルとのAPI通信を担当します。
    -   `Persistence`: SwiftDataのセットアップやマイグレーションなど、永続化に関する詳細な実装を配置します。

-   **`Resources`**: 画像アセット、ローカライズ文字列ファイルなど、コード以外のリソースを管理します。

-   **`Utilities`**: プロジェクト全体で利用される汎用的なヘルパーや拡張機能（`Date`のフォーマットなど）を配置します。

-   **`MyTrainingAppWidget`**: ホーム画面に表示されるWidgetのターゲットです。

-   **`*Tests`**: ユニットテストとUIテストのコードを配置します。

-   **`design_docs`**: このドキュメントのように、設計に関する資料を格納します。
