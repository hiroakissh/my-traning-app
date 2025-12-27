import Foundation

enum PlanStatus: String, Codable, CaseIterable {
    case planned
    case inProgress
    case paused
    case completed
}

enum SuggestionSource: String, Codable, CaseIterable {
    case ai
    case user
    case system
}

enum ProgressTrend: String, Codable, CaseIterable {
    case upward
    case downward
    case steady
}

struct PlanMetric: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var unit: String
    var currentValue: Double
    var targetValue: Double
    var trend: ProgressTrend

    init(id: UUID = UUID(), name: String, unit: String, currentValue: Double, targetValue: Double, trend: ProgressTrend) {
        self.id = id
        self.name = name
        self.unit = unit
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.trend = trend
    }

    var progressRate: Double {
        guard targetValue > 0 else { return 0 }
        let raw = currentValue / targetValue
        return min(max(raw, 0), 1)
    }
}

struct PlanProgress: Codable, Equatable {
    var streakDays: Int
    var completedMilestones: Int
    var totalMilestones: Int
    var metrics: [PlanMetric]
    var note: String?

    init(
        streakDays: Int,
        completedMilestones: Int,
        totalMilestones: Int,
        metrics: [PlanMetric] = [],
        note: String? = nil
    ) {
        self.streakDays = streakDays
        self.completedMilestones = completedMilestones
        self.totalMilestones = totalMilestones
        self.metrics = metrics
        self.note = note
    }

    var overallRate: Double {
        guard !metrics.isEmpty else { return 0 }
        let sum = metrics.map { $0.progressRate }.reduce(0, +)
        return min(max(sum / Double(metrics.count), 0), 1)
    }

    var milestoneCompletionRate: Double {
        guard totalMilestones > 0 else { return 0 }
        let raw = Double(completedMilestones) / Double(totalMilestones)
        return min(max(raw, 0), 1)
    }

    var progressedMetricsCount: Int {
        metrics.count
    }
}

struct Plan: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var horizon: PlanHorizon
    var startDate: Date
    var endDate: Date
    var status: PlanStatus
    var progress: PlanProgress
    var metrics: [PlanMetric]
    var suggestions: [PlanSuggestion]

    init(
        id: UUID = UUID(),
        title: String,
        horizon: PlanHorizon,
        startDate: Date,
        endDate: Date,
        status: PlanStatus = .planned,
        progress: PlanProgress,
        metrics: [PlanMetric] = [],
        suggestions: [PlanSuggestion] = []
    ) {
        self.id = id
        self.title = title
        self.horizon = horizon
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.progress = progress
        self.metrics = metrics
        self.suggestions = suggestions
    }
}
