import Foundation

struct RecordingSessionTargets: Equatable, Codable {
    var time: TimeInterval?
    var distance: Double?
    var activeCalories: Double?
    var averageHeartRate: Double?

    init(time: TimeInterval? = nil, distance: Double? = nil, activeCalories: Double? = nil, averageHeartRate: Double? = nil) {
        self.time = time
        self.distance = distance
        self.activeCalories = activeCalories
        self.averageHeartRate = averageHeartRate
    }
}

struct RecordingSessionState: Equatable, Codable {
    var elapsed: TimeInterval
    var distance: Double
    var activeCalories: Double
    var heartRateSamples: [Double]
    var targets: RecordingSessionTargets

    init(
        elapsed: TimeInterval,
        distance: Double,
        activeCalories: Double,
        heartRateSamples: [Double] = [],
        targets: RecordingSessionTargets = RecordingSessionTargets()
    ) {
        self.elapsed = elapsed
        self.distance = distance
        self.activeCalories = activeCalories
        self.heartRateSamples = heartRateSamples
        self.targets = targets
    }

    var averageHeartRate: Double? {
        guard !heartRateSamples.isEmpty else { return nil }
        let sum = heartRateSamples.reduce(0, +)
        return sum / Double(heartRateSamples.count)
    }

    var timeProgress: Double? {
        progressRate(current: elapsed, target: targets.time)
    }

    var distanceProgress: Double? {
        progressRate(current: distance, target: targets.distance)
    }

    var calorieProgress: Double? {
        progressRate(current: activeCalories, target: targets.activeCalories)
    }

    var heartRateProgress: Double? {
        guard let averageHeartRate, let target = targets.averageHeartRate, target > 0 else { return nil }
        return clampedProgress(current: averageHeartRate / target)
    }

    mutating func addHeartRateSample(_ sample: Double) {
        heartRateSamples.append(sample)
    }

    private func progressRate(current: Double, target: Double?) -> Double? {
        guard let target, target > 0 else { return nil }
        return clampedProgress(current: current / target)
    }

    private func clampedProgress(current: Double) -> Double {
        min(max(current, 0), 1)
    }
}
