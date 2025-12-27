# Tasks: 記録画面 & HealthKit連携

1. **ユニットテスト作成**: CardioMetricsのペース計算、HealthDataSnapshotの合計エネルギー計算/フォーマットのテストを追加。
2. **ドメイン実装**: TrainingLog、StrengthExerciseLog、CardioExerciseLog、HealthDataSnapshot、CardioMetricsのモデルと計算ロジックを実装。
3. **インフラ実装**: HealthDataProvidingプロトコルとモック実装をInfrastructure/HealthKit配下に作成。
4. **UI実装**: RecordingViewに日付選択、筋トレセット入力、ランニング入力、ヘルスデータサマリー、保存ボタンを実装し、開始時にヘルスデータ取得をトリガー。
5. **設計ドキュメント更新**: 画面仕様にヘルスケアデータ利用一覧を追記し、仕様/計画との整合を確認。
