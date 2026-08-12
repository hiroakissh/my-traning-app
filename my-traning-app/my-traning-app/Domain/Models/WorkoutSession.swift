import Foundation
import SwiftData

enum WorkoutSessionStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case completed
    case partiallyCompleted
    case cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted:
            return "未開始"
        case .inProgress:
            return "実行中"
        case .completed:
            return "完了"
        case .partiallyCompleted:
            return "一部完了"
        case .cancelled:
            return "キャンセル"
        }
    }
}

enum ExerciseSessionStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case completed
    case skipped

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted:
            return "未開始"
        case .inProgress:
            return "実行中"
        case .completed:
            return "完了"
        case .skipped:
            return "スキップ"
        }
    }
}

enum SetStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case completed
    case modified
    case skipped

    var id: String { rawValue }

    var isExecuted: Bool {
        self == .completed || self == .modified
    }

    var displayName: String {
        switch self {
        case .planned:
            return "予定"
        case .completed:
            return "完了"
        case .modified:
            return "変更して完了"
        case .skipped:
            return "スキップ"
        }
    }
}

enum SimpleRPE: String, Codable, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:
            return "軽い"
        case .normal:
            return "普通"
        case .hard:
            return "きつい"
        }
    }

    var rpeValue: Int {
        switch self {
        case .easy:
            return 5
        case .normal:
            return 7
        case .hard:
            return 9
        }
    }
}

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var recommendationId: UUID?
    var goalId: UUID?
    var startedAt: Date
    var endedAt: Date?
    var statusRaw: String
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutSessionExercise]
    var userNote: String?

    var status: WorkoutSessionStatus {
        get { WorkoutSessionStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        recommendationId: UUID? = nil,
        goalId: UUID? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: WorkoutSessionStatus = .notStarted,
        exercises: [WorkoutSessionExercise] = [],
        userNote: String? = nil
    ) {
        self.id = id
        self.recommendationId = recommendationId
        self.goalId = goalId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = status.rawValue
        self.exercises = exercises
        self.userNote = userNote
    }
}

@Model
final class WorkoutSessionExercise {
    @Attribute(.unique) var id: UUID
    var plannedExerciseId: UUID?
    var name: String
    var order: Int
    @Relationship(deleteRule: .cascade) var plannedSets: [PlannedSet]
    @Relationship(deleteRule: .cascade) var actualSets: [ActualSet]
    var statusRaw: String
    var categoryRaw: String

    var status: ExerciseSessionStatus {
        get { ExerciseSessionStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        plannedExerciseId: UUID? = nil,
        name: String,
        order: Int,
        plannedSets: [PlannedSet],
        actualSets: [ActualSet],
        status: ExerciseSessionStatus = .notStarted,
        category: ExerciseCategory = .other
    ) {
        self.id = id
        self.plannedExerciseId = plannedExerciseId
        self.name = name
        self.order = order
        self.plannedSets = plannedSets
        self.actualSets = actualSets
        self.statusRaw = status.rawValue
        self.categoryRaw = category.rawValue
    }
}

@Model
final class PlannedSet {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weight: Double?
    var reps: Int?
    var durationSeconds: Int?
    var distanceMeters: Double?

    init(
        id: UUID = UUID(),
        order: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
    }
}

@Model
final class ActualSet {
    @Attribute(.unique) var id: UUID
    var plannedSetId: UUID?
    var order: Int
    var weight: Double?
    var reps: Int?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var rpe: Int?
    var completedAt: Date?
    var statusRaw: String

    var status: SetStatus {
        get { SetStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        plannedSetId: UUID? = nil,
        order: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        distanceMeters: Double? = nil,
        rpe: Int? = nil,
        completedAt: Date? = nil,
        status: SetStatus = .planned
    ) {
        self.id = id
        self.plannedSetId = plannedSetId
        self.order = order
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.rpe = rpe
        self.completedAt = completedAt
        self.statusRaw = status.rawValue
    }
}
