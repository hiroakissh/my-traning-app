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

// MARK: - Models

@Model
final class TrainingLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var sessionDurationSec: Int?
    var purpose: TrainingPurpose
    @Relationship(deleteRule: .cascade) var condition: TrainingCondition?
    @Relationship(deleteRule: .cascade) var exercises: [TrainingExercise]
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        sessionDurationSec: Int? = nil,
        purpose: TrainingPurpose,
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
        self.condition = condition
        self.exercises = exercises
        self.note = note
    }
}

@Model
final class TrainingCondition {
    var sleepHours: Double?
    var sleepQuality: Int?
    var fatigueLevel: Int?
    var mood: Int?
    var soreness: Int?
    var conditionNote: String?

    @Relationship(inverse: \TrainingLog.condition) var log: TrainingLog?

    init(
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        fatigueLevel: Int? = nil,
        mood: Int? = nil,
        soreness: Int? = nil,
        conditionNote: String? = nil
    ) {
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
    var bodyPart: String?
    var category: ExerciseCategory
    @Relationship(deleteRule: .cascade) var sets: [TrainingSet]
    var note: String?

    @Relationship(inverse: \TrainingLog.exercises) var log: TrainingLog?

    init(
        id: UUID = UUID(),
        name: String,
        bodyPart: String? = nil,
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
    var order: Int
    var weightKg: Double?
    var reps: Int?
    var durationSec: Int?
    var rpe: Double?
    var restSec: Int?
    var setNote: String?

    @Relationship(inverse: \TrainingExercise.sets) var exercise: TrainingExercise?

    init(
        order: Int,
        weightKg: Double? = nil,
        reps: Int? = nil,
        durationSec: Int? = nil,
        rpe: Double? = nil,
        restSec: Int? = nil,
        setNote: String? = nil
    ) {
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
        self.durationSec = durationSec
        self.rpe = rpe
        self.restSec = restSec
        self.setNote = setNote
    }
}
