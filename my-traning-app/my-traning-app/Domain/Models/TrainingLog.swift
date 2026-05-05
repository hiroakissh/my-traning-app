import Foundation
import SwiftData

enum TrainingPurpose: String, CaseIterable, Codable, Equatable {
    case refresh
    case hypertrophy
    case diet
    case tune
    case other

    var displayName: String {
        switch self {
        case .refresh:
            return "リフレッシュ"
        case .hypertrophy:
            return "筋肥大"
        case .diet:
            return "減量"
        case .tune:
            return "調整"
        case .other:
            return "その他"
        }
    }
}

enum TrainingLogSource: String, CaseIterable, Codable, Equatable {
    case timer
    case manual
    case imported
    case unknown
}

enum BodyPart: String, CaseIterable, Codable, Equatable {
    case chest
    case back
    case legs
    case shoulder
    case arms
    case core
    case fullBody
    case other
}

enum ExerciseCategory: String, CaseIterable, Codable, Equatable {
    case strength
    case cardio
    case mobility
    case other
}

@Model
final class TrainingCondition: Identifiable {
    @Attribute(.unique) var id: UUID
    var sleepHours: Double?
    var sleepQuality: Int?
    var fatigueLevel: Int?
    var mood: Int?
    var soreness: Int?
    var conditionNote: String?
    var overallCondition: Int?

    init(
        id: UUID = UUID(),
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        fatigueLevel: Int? = nil,
        mood: Int? = nil,
        soreness: Int? = nil,
        conditionNote: String? = nil,
        overallCondition: Int? = nil
    ) {
        self.id = id
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.fatigueLevel = fatigueLevel
        self.mood = mood
        self.soreness = soreness
        self.conditionNote = conditionNote
        self.overallCondition = overallCondition
    }
}

@Model
final class TrainingSet: Identifiable {
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

@Model
final class TrainingExercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var bodyPart: BodyPart
    var category: ExerciseCategory
    @Relationship(deleteRule: .cascade) var sets: [TrainingSet]
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        bodyPart: BodyPart,
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
final class TrainingLog: Identifiable {
    @Attribute(.unique) var id: UUID
    var recommendationId: UUID?
    var workoutSessionId: UUID?
    var goalId: UUID?
    var date: Date
    var startedAt: Date?
    var endedAt: Date?
    var sessionDurationSec: Int
    var purpose: TrainingPurpose
    var source: TrainingLogSource
    var activityResultRaw: String
    var condition: TrainingCondition?
    @Relationship(deleteRule: .cascade) var exercises: [TrainingExercise]
    @Transient var strengthExercises: [StrengthExerciseLog] = []
    @Transient var cardio: CardioExerciseLog?
    @Transient var healthSnapshot: HealthDataSnapshot?
    var averageRPE: Double?
    var note: String?
    var createdAt: Date
    var wasPlanned: Bool
    var wasShortened: Bool
    var hadSkippedItems: Bool
    var changedToRest: Bool
    var planDeltaSummary: String?

    // エイリアス（設計ドキュメントのフィールド名に合わせる）
    @Transient
    var startTime: Date? {
        get { startedAt }
        set { startedAt = newValue }
    }

    @Transient
    var endTime: Date? {
        get { endedAt }
        set { endedAt = newValue }
    }

    @Transient
    var totalDurationMinutes: Int {
        max(sessionDurationSec / 60, 0)
    }

    var activityResult: ActivityResult {
        get { ActivityResult(rawValue: activityResultRaw) ?? .completed }
        set { activityResultRaw = newValue.rawValue }
    }

    var userNote: String? {
        get { note }
        set { note = newValue }
    }

    init(
        id: UUID = UUID(),
        recommendationId: UUID? = nil,
        workoutSessionId: UUID? = nil,
        goalId: UUID? = nil,
        date: Date,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        sessionDurationSec: Int,
        purpose: TrainingPurpose,
        source: TrainingLogSource,
        activityResult: ActivityResult = .completed,
        condition: TrainingCondition? = nil,
        exercises: [TrainingExercise] = [],
        strengthExercises: [StrengthExerciseLog] = [],
        cardio: CardioExerciseLog? = nil,
        healthSnapshot: HealthDataSnapshot? = nil,
        averageRPE: Double? = nil,
        note: String? = nil,
        createdAt: Date = Date(),
        wasPlanned: Bool = false,
        wasShortened: Bool = false,
        hadSkippedItems: Bool = false,
        changedToRest: Bool = false,
        planDeltaSummary: String? = nil
    ) {
        self.id = id
        self.recommendationId = recommendationId
        self.workoutSessionId = workoutSessionId
        self.goalId = goalId
        self.date = date
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.sessionDurationSec = sessionDurationSec
        self.purpose = purpose
        self.source = source
        self.activityResultRaw = activityResult.rawValue
        self.condition = condition
        self.exercises = exercises
        self.strengthExercises = strengthExercises
        self.cardio = cardio
        self.healthSnapshot = healthSnapshot
        self.averageRPE = averageRPE
        self.note = note
        self.createdAt = createdAt
        self.wasPlanned = wasPlanned
        self.wasShortened = wasShortened
        self.hadSkippedItems = hadSkippedItems
        self.changedToRest = changedToRest
        self.planDeltaSummary = planDeltaSummary
    }
}

struct StrengthExerciseLog: Identifiable, Equatable {
    let id: UUID
    var name: String
    var bodyPart: BodyPart
    var category: ExerciseCategory
    var sets: [StrengthSetLog]
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        bodyPart: BodyPart = .other,
        category: ExerciseCategory = .strength,
        sets: [StrengthSetLog] = [],
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

struct StrengthSetLog: Identifiable, Equatable {
    let id: UUID
    var weight: Double?
    var repetitions: Int?
    var durationSec: Int?
    var rpe: Double?
    var restSec: Int?
    var setNote: String?
    var isWarmup: Bool
    var isBodyweight: Bool

    init(
        id: UUID = UUID(),
        weight: Double? = nil,
        repetitions: Int? = nil,
        durationSec: Int? = nil,
        rpe: Double? = nil,
        restSec: Int? = nil,
        setNote: String? = nil,
        isWarmup: Bool = false,
        isBodyweight: Bool = false
    ) {
        self.id = id
        self.weight = weight
        self.repetitions = repetitions
        self.durationSec = durationSec
        self.rpe = rpe
        self.restSec = restSec
        self.setNote = setNote
        self.isWarmup = isWarmup
        self.isBodyweight = isBodyweight
    }
}

struct CardioExerciseLog: Identifiable, Equatable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var distanceInKilometers: Double
    var durationInSeconds: TimeInterval
    var pace: Double
    var note: String?

    init(
        id: UUID = UUID(),
        name: String = "Cardio",
        category: ExerciseCategory = .cardio,
        distanceInKilometers: Double,
        durationInSeconds: TimeInterval,
        pace: Double,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.distanceInKilometers = distanceInKilometers
        self.durationInSeconds = durationInSeconds
        self.pace = pace
        self.note = note
    }
}

struct CardioMetrics: Equatable {
    var distanceInKilometers: Double
    var durationInSeconds: TimeInterval

    var pacePerKilometer: Double {
        guard distanceInKilometers > 0 else { return 0 }
        return durationInSeconds / distanceInKilometers
    }

    var formattedPace: String {
        let totalSeconds = Int(pacePerKilometer.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

struct HealthDataSnapshot: Equatable {
    var start: Date
    var end: Date
    var averageHeartRate: Double?
    var restingHeartRate: Double?
    var activeEnergyBurned: Double?
    var basalEnergyBurned: Double?
    var distanceWalkingRunning: Double?
    var stepCount: Int?
    var vo2Max: Double?

    var totalEnergyBurned: Double? {
        guard let active = activeEnergyBurned else { return nil }
        if let basal = basalEnergyBurned {
            return active + basal
        }
        return active
    }

    var availableMetrics: [String: String] {
        var metrics: [String: String] = [:]
        if let averageHeartRate {
            metrics["平均心拍数"] = "\(Int(averageHeartRate)) bpm"
        }
        if let totalEnergy = totalEnergyBurned {
            metrics["消費カロリー"] = "\(Int(totalEnergy.rounded())) kcal"
        }
        if let stepCount {
            metrics["歩数"] = "\(stepCount) steps"
        }
        if let distanceWalkingRunning {
            metrics["距離"] = String(format: "%.1f km", distanceWalkingRunning)
        }
        if let vo2Max {
            metrics["VO2Max"] = String(format: "%.1f mL/kg/min", vo2Max)
        }
        return metrics
    }
}
