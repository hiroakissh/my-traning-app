import Foundation

struct TrainingLog: Identifiable, Equatable {
    let id: UUID
    var date: Date
    var startedAt: Date?
    var strengthExercises: [StrengthExerciseLog]
    var cardio: CardioExerciseLog?
    var healthSnapshot: HealthDataSnapshot?

    init(
        id: UUID = UUID(),
        date: Date,
        startedAt: Date? = nil,
        strengthExercises: [StrengthExerciseLog] = [],
        cardio: CardioExerciseLog? = nil,
        healthSnapshot: HealthDataSnapshot? = nil
    ) {
        self.id = id
        self.date = date
        self.startedAt = startedAt
        self.strengthExercises = strengthExercises
        self.cardio = cardio
        self.healthSnapshot = healthSnapshot
    }
}

struct StrengthExerciseLog: Identifiable, Equatable {
    let id: UUID
    var name: String
    var sets: [StrengthSetLog]

    init(id: UUID = UUID(), name: String, sets: [StrengthSetLog] = []) {
        self.id = id
        self.name = name
        self.sets = sets
    }
}

struct StrengthSetLog: Identifiable, Equatable {
    let id: UUID
    var weight: Double?
    var repetitions: Int?

    init(id: UUID = UUID(), weight: Double? = nil, repetitions: Int? = nil) {
        self.id = id
        self.weight = weight
        self.repetitions = repetitions
    }
}

struct CardioExerciseLog: Identifiable, Equatable {
    let id: UUID
    var distanceInKilometers: Double
    var durationInSeconds: TimeInterval
    var pace: Double

    init(
        id: UUID = UUID(),
        distanceInKilometers: Double,
        durationInSeconds: TimeInterval,
        pace: Double
    ) {
        self.id = id
        self.distanceInKilometers = distanceInKilometers
        self.durationInSeconds = durationInSeconds
        self.pace = pace
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
