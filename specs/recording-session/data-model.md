# Data Model: Recording Session

## TrainingLog
- `id: UUID`
- `date: Date`
- `startedAt: Date?`
- `strengthExercises: [StrengthExerciseLog]`
- `cardio: CardioExerciseLog?`
- `healthSnapshot: HealthDataSnapshot?`

## StrengthExerciseLog
- `id: UUID`
- `name: String`
- `sets: [StrengthSetLog]`

## StrengthSetLog
- `id: UUID`
- `weight: Double?` (kg)
- `repetitions: Int?`

## CardioExerciseLog
- `id: UUID`
- `distanceInKilometers: Double`
- `durationInSeconds: TimeInterval`
- `pace: Double` (秒/ km、`CardioMetrics`で計算)

## CardioMetrics
- `distanceInKilometers: Double`
- `durationInSeconds: TimeInterval`
- `var pacePerKilometer: Double` (計算プロパティ)

## HealthDataSnapshot
- `start: Date`
- `end: Date`
- `averageHeartRate: Double?`
- `restingHeartRate: Double?`
- `activeEnergyBurned: Double?` (kcal)
- `basalEnergyBurned: Double?` (kcal)
- `distanceWalkingRunning: Double?` (km)
- `stepCount: Int?`
- `vo2Max: Double?`
- `var totalEnergyBurned: Double?` (合算計算)
- `var availableMetrics: [String: String]` (UI表示向けフォーマット)
