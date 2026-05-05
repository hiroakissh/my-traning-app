import Foundation
import SwiftData

enum SleepQuality: String, Codable, CaseIterable, Identifiable {
    case poor
    case normal
    case good

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .poor: return "悪い"
        case .normal: return "普通"
        case .good: return "良い"
        }
    }
}

enum FatigueLevel: String, Codable, CaseIterable, Identifiable {
    case high
    case normal
    case low

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .high: return "重い"
        case .normal: return "普通"
        case .low: return "軽い"
        }
    }
}

enum MoodLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "低い"
        case .normal: return "普通"
        case .high: return "高い"
        }
    }
}

enum SorenessLevel: String, Codable, CaseIterable, Identifiable {
    case none
    case mild
    case strong

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "なし"
        case .mild: return "少し"
        case .strong: return "強い"
        }
    }
}

enum MotivationLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "低い"
        case .normal: return "普通"
        case .high: return "高い"
        }
    }
}

enum ReadinessLevel: String, Codable, CaseIterable, Identifiable {
    case go
    case easy
    case rest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .go: return "いける"
        case .easy: return "軽め"
        case .rest: return "休む"
        }
    }

    var systemImage: String {
        switch self {
        case .go: return "bolt.fill"
        case .easy: return "leaf.fill"
        case .rest: return "moon.zzz.fill"
        }
    }
}

enum RecommendationType: String, Codable, CaseIterable, Identifiable {
    case fullWorkout
    case lightWorkout
    case recovery
    case rest
    case consultation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullWorkout: return "通常トレーニング"
        case .lightWorkout: return "軽めの運動"
        case .recovery: return "回復メニュー"
        case .rest: return "休養"
        case .consultation: return "相談"
        }
    }

    var defaultPurpose: TrainingPurpose {
        switch self {
        case .fullWorkout:
            return .hypertrophy
        case .lightWorkout:
            return .tune
        case .recovery, .rest:
            return .refresh
        case .consultation:
            return .other
        }
    }
}

enum AcceptedAction: String, Codable, CaseIterable, Identifiable {
    case startedOriginalPlan
    case startedShortPlan
    case changedToRest
    case requestedAnotherPlan
    case skipped

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .startedOriginalPlan: return "予定通り開始"
        case .startedShortPlan: return "短縮版を開始"
        case .changedToRest: return "休養日に変更"
        case .requestedAnotherPlan: return "別メニューを依頼"
        case .skipped: return "スキップ"
        }
    }
}

enum ActivityResult: String, Codable, CaseIterable, Identifiable {
    case completed
    case partiallyCompleted
    case recoveryCompleted
    case rested
    case skipped

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .completed: return "完了"
        case .partiallyCompleted: return "一部完了"
        case .recoveryCompleted: return "回復メニュー完了"
        case .rested: return "休養"
        case .skipped: return "スキップ"
        }
    }
}

enum RecommendationGenerationSource: String, Codable, CaseIterable, Identifiable {
    case ai
    case ruleBased

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ai:
            return "AI提案"
        case .ruleBased:
            return "安全メニュー"
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case race
    case strength
    case diet
    case health
    case mentalRecovery
    case habit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .race: return "大会・レース"
        case .strength: return "筋力アップ"
        case .diet: return "ダイエット"
        case .health: return "健康維持"
        case .mentalRecovery: return "メンタル回復"
        case .habit: return "習慣化"
        }
    }

    var policySummary: String {
        switch self {
        case .race:
            return "期限から逆算し、疲労を溜めすぎない調整を優先します。"
        case .strength:
            return "重量・回数・セット数の成長を見ながら漸進性を優先します。"
        case .diet:
            return "継続可能な運動量と疲労・睡眠のバランスを優先します。"
        case .health:
            return "歩数、軽運動、ストレッチを中心に達成ハードルを下げます。"
        case .mentalRecovery:
            return "気分改善を主目的に、散歩や呼吸、軽い動きを優先します。"
        case .habit:
            return "5分から再開できるメニューで継続しやすさを優先します。"
        }
    }
}

@Model
final class DailyCheckIn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sleepQualityRaw: String
    var fatigueLevelRaw: String
    var moodLevelRaw: String
    var sorenessLevelRaw: String
    var availableMinutes: Int
    var motivationLevelRaw: String
    var note: String?

    var sleepQuality: SleepQuality {
        get { SleepQuality(rawValue: sleepQualityRaw) ?? .normal }
        set { sleepQualityRaw = newValue.rawValue }
    }

    var fatigueLevel: FatigueLevel {
        get { FatigueLevel(rawValue: fatigueLevelRaw) ?? .normal }
        set { fatigueLevelRaw = newValue.rawValue }
    }

    var moodLevel: MoodLevel {
        get { MoodLevel(rawValue: moodLevelRaw) ?? .normal }
        set { moodLevelRaw = newValue.rawValue }
    }

    var sorenessLevel: SorenessLevel {
        get { SorenessLevel(rawValue: sorenessLevelRaw) ?? .none }
        set { sorenessLevelRaw = newValue.rawValue }
    }

    var motivationLevel: MotivationLevel {
        get { MotivationLevel(rawValue: motivationLevelRaw) ?? .normal }
        set { motivationLevelRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sleepQuality: SleepQuality,
        fatigueLevel: FatigueLevel,
        moodLevel: MoodLevel,
        sorenessLevel: SorenessLevel,
        availableMinutes: Int,
        motivationLevel: MotivationLevel,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sleepQualityRaw = sleepQuality.rawValue
        self.fatigueLevelRaw = fatigueLevel.rawValue
        self.moodLevelRaw = moodLevel.rawValue
        self.sorenessLevelRaw = sorenessLevel.rawValue
        self.availableMinutes = availableMinutes
        self.motivationLevelRaw = motivationLevel.rawValue
        self.note = note
    }
}

@Model
final class PlannedExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var name: String
    var detail: String
    var targetSets: Int?
    var targetReps: Int?
    var weightDescription: String?
    var estimatedMinutes: Int
    var categoryRaw: String

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        order: Int,
        name: String,
        detail: String,
        targetSets: Int? = nil,
        targetReps: Int? = nil,
        weightDescription: String? = nil,
        estimatedMinutes: Int = 0,
        category: ExerciseCategory = .other
    ) {
        self.id = id
        self.order = order
        self.name = name
        self.detail = detail
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.weightDescription = weightDescription
        self.estimatedMinutes = estimatedMinutes
        self.categoryRaw = category.rawValue
    }
}

@Model
final class AlternativePlan {
    @Attribute(.unique) var id: UUID
    var title: String
    var planDescription: String
    var estimatedMinutes: Int
    var intensity: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        estimatedMinutes: Int,
        intensity: Int
    ) {
        self.id = id
        self.title = title
        self.planDescription = description
        self.estimatedMinutes = estimatedMinutes
        self.intensity = min(max(intensity, 1), 10)
    }
}

@Model
final class DailyRecommendation {
    @Attribute(.unique) var id: UUID
    var date: Date
    var readinessLevelRaw: String
    var recommendationTypeRaw: String
    var title: String
    var summary: String
    var reasonsStorage: String
    @Relationship(deleteRule: .cascade) var plannedExercises: [PlannedExercise]
    @Relationship(deleteRule: .cascade) var alternatives: [AlternativePlan]
    var recoveryAdviceStorage: String
    var generatedAt: Date
    var acceptedActionRaw: String?
    var generationSourceRaw: String
    var generationNotice: String?

    var readinessLevel: ReadinessLevel {
        get { ReadinessLevel(rawValue: readinessLevelRaw) ?? .easy }
        set { readinessLevelRaw = newValue.rawValue }
    }

    var recommendationType: RecommendationType {
        get { RecommendationType(rawValue: recommendationTypeRaw) ?? .lightWorkout }
        set { recommendationTypeRaw = newValue.rawValue }
    }

    var reasons: [String] {
        get { RecommendationTextListCodec.decode(reasonsStorage) }
        set { reasonsStorage = RecommendationTextListCodec.encode(newValue) }
    }

    var recoveryAdvice: [String] {
        get { RecommendationTextListCodec.decode(recoveryAdviceStorage) }
        set { recoveryAdviceStorage = RecommendationTextListCodec.encode(newValue) }
    }

    var acceptedAction: AcceptedAction? {
        get { acceptedActionRaw.flatMap(AcceptedAction.init(rawValue:)) }
        set { acceptedActionRaw = newValue?.rawValue }
    }

    var generationSource: RecommendationGenerationSource {
        get { RecommendationGenerationSource(rawValue: generationSourceRaw) ?? .ai }
        set { generationSourceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        readinessLevel: ReadinessLevel,
        recommendationType: RecommendationType,
        title: String,
        summary: String,
        reasons: [String],
        plannedExercises: [PlannedExercise],
        alternatives: [AlternativePlan],
        recoveryAdvice: [String],
        generatedAt: Date = Date(),
        acceptedAction: AcceptedAction? = nil,
        generationSource: RecommendationGenerationSource = .ai,
        generationNotice: String? = nil
    ) {
        self.id = id
        self.date = date
        self.readinessLevelRaw = readinessLevel.rawValue
        self.recommendationTypeRaw = recommendationType.rawValue
        self.title = title
        self.summary = summary
        self.reasonsStorage = RecommendationTextListCodec.encode(reasons)
        self.plannedExercises = plannedExercises
        self.alternatives = alternatives
        self.recoveryAdviceStorage = RecommendationTextListCodec.encode(recoveryAdvice)
        self.generatedAt = generatedAt
        self.acceptedActionRaw = acceptedAction?.rawValue
        self.generationSourceRaw = generationSource.rawValue
        self.generationNotice = generationNotice
    }
}

@Model
final class UserGoal {
    @Attribute(.unique) var id: UUID
    var goalTypeRaw: String
    var title: String
    var targetDate: Date?
    var targetMetric: String?
    var priority: Int
    var createdAt: Date
    var updatedAt: Date

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .health }
        set { goalTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        goalType: GoalType,
        title: String,
        targetDate: Date? = nil,
        targetMetric: String? = nil,
        priority: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalTypeRaw = goalType.rawValue
        self.title = title
        self.targetDate = targetDate
        self.targetMetric = targetMetric
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class WeeklyReview {
    @Attribute(.unique) var id: UUID
    var weekStartDate: Date
    var adherenceRate: Double
    var completedWorkoutCount: Int
    var recoveryDayCount: Int
    var skippedCount: Int
    var highlightsStorage: String
    var issuesStorage: String
    var nextWeekStrategy: String
    var generatedAt: Date

    var highlights: [String] {
        get { RecommendationTextListCodec.decode(highlightsStorage) }
        set { highlightsStorage = RecommendationTextListCodec.encode(newValue) }
    }

    var issues: [String] {
        get { RecommendationTextListCodec.decode(issuesStorage) }
        set { issuesStorage = RecommendationTextListCodec.encode(newValue) }
    }

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        adherenceRate: Double,
        completedWorkoutCount: Int,
        recoveryDayCount: Int,
        skippedCount: Int,
        highlights: [String],
        issues: [String],
        nextWeekStrategy: String,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.adherenceRate = min(max(adherenceRate, 0), 1)
        self.completedWorkoutCount = completedWorkoutCount
        self.recoveryDayCount = recoveryDayCount
        self.skippedCount = skippedCount
        self.highlightsStorage = RecommendationTextListCodec.encode(highlights)
        self.issuesStorage = RecommendationTextListCodec.encode(issues)
        self.nextWeekStrategy = nextWeekStrategy
        self.generatedAt = generatedAt
    }
}

private enum RecommendationTextListCodec {
    static func encode(_ values: [String]) -> String {
        let cleaned = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let data = try? JSONEncoder().encode(cleaned),
              let json = String(data: data, encoding: .utf8) else {
            return cleaned.joined(separator: "\n")
        }
        return json
    }

    static func decode(_ rawValue: String) -> [String] {
        guard !rawValue.isEmpty else { return [] }
        if let data = rawValue.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return decoded
        }
        return rawValue
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
