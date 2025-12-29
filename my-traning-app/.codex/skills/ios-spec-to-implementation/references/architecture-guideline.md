# SwiftUI + SwiftData アーキテクチャ指針（簡易）

- **データ層**: SwiftData `@Model` を単一責務で定義し、IDは `UUID` を原則。`ModelContext` は `Repository` に注入する。
- **DI/テスタビリティ**: `protocol Repository` を用意し、`DefaultRepository` を本番実装とする。テスト時はインメモリ `ModelContainer` を渡すか、モックを差し替える。
- **状態管理**: UI は `@State`/`@Bindable`/`@ObservationIgnored` を組み合わせ、ビジネスロジックは `@Observable` な ViewModel/Store に集約する。
- **非同期処理**: View からは `Task { await viewModel.load() }` のように明示し、エラーハンドリングは ViewModel が状態に反映。
- **SwiftUI 構造**: `NavigationStack` を基本に、小さな `View` に分割。`Preview` ではインメモリ `ModelContainer` を使う。
- **テスト**: Unit テストは Repository と ViewModel の契約に対して行い、状態遷移（追加・削除・フィルタリング）をカバー。UI スナップショットは主要パスのみ。
