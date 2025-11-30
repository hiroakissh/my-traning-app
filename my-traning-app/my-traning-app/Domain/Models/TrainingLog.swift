import Foundation
import SwiftData

// MARK: - Enums

enum TrainingPurpose: String, Codable, CaseIterable {
    case refresh
    case hypertrophy
    case diet
    case tune
    case other
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case strength
    case cardio
    case mobility
    case other
}

enum BodyPart: String, Codable, CaseIterable {
    case chest
    case back
    case legs
    case shoulder
    case arms
    case core
    case fullBody
    case other

    var displayName: String {
        switch self {
        case .chest: "胸"
        case .back: "背中"
        case .legs: "脚"
        case .shoulder: "肩"
        case .arms: "腕"
        case .core: "体幹"
        case .fullBody: "全身"
        case .other: "その他"
        }
    }
}

enum LogSource: String, Codable, CaseIterable {
    case timer
    case manual
    case imported
}

// MARK: - Models

@Model
final class TrainingLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var sessionDurationSec: Int
    var purpose: TrainingPurpose
    var source: LogSource
    @Relationship(deleteRule: .cascade) var condition: TrainingCondition?
    @Relationship(deleteRule: .cascade) var exercises: [TrainingExercise]
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        sessionDurationSec: Int,
        purpose: TrainingPurpose,
        source: LogSource,
        condition: TrainingCondition? = nil,
        exercises: [TrainingExercise] = [],
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.sessionDurationSec = sessionDurationSec
        self.purpose = purpose
        self.source = source
        self.condition = condition
        self.exercises = exercises
        self.note = note
    }
}

@Model
final class TrainingCondition {
    var overallCondition: Int
    var sleepHours: Double?
    var sleepQuality: Int?
    var fatigueLevel: Int?
    var mood: Int?
    var soreness: Int?
    var conditionNote: String?

    @Relationship(inverse: \TrainingLog.condition) var log: TrainingLog?

    init(
        overallCondition: Int,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        fatigueLevel: Int? = nil,
        mood: Int? = nil,
        soreness: Int? = nil,
        conditionNote: String? = nil
    ) {
        self.overallCondition = overallCondition
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.fatigueLevel = fatigueLevel
        self.mood = mood
        self.soreness = soreness
        self.conditionNote = conditionNote
    }
}

@Model
final class TrainingExercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var bodyPart: BodyPart
    var category: ExerciseCategory
    @Relationship(deleteRule: .cascade) var sets: [TrainingSet]
    var note: String?

    @Relationship(inverse: \TrainingLog.exercises) var log: TrainingLog?

    init(
        id: UUID = UUID(),
        name: String,
        bodyPart: BodyPart = .other,
        category: ExerciseCategory = .strength,
        sets: [TrainingSet] = [],
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.category = category
        self.sets = sets
        self.note = note
    }
}

@Model
final class TrainingSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weightKg: Double?
    var reps: Int?
    var durationSec: Int?
    var rpe: Double?
    var restSec: Int?
    var setNote: String?
    var isWarmup: Bool
    var isBodyweight: Bool

    @Relationship(inverse: \TrainingExercise.sets) var exercise: TrainingExercise?

    init(
        id: UUID = UUID(),
        order: Int,
        weightKg: Double? = nil,
        reps: Int? = nil,
        durationSec: Int? = nil,
        rpe: Double? = nil,
        restSec: Int? = nil,
        setNote: String? = nil,
        isWarmup: Bool = false,
        isBodyweight: Bool = false
    ) {
        self.id = id
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
        self.durationSec = durationSec
        self.rpe = rpe
        self.restSec = restSec
        self.setNote = setNote
        self.isWarmup = isWarmup
        self.isBodyweight = isBodyweight
    }
}
