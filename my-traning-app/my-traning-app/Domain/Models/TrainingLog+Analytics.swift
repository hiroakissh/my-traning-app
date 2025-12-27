import Foundation

struct DailyLogSummary {
    let date: Date
    let logs: [TrainingLog]
    let totalDurationSec: Int
    let totalVolumeKg: Double
    let purposeCounts: [TrainingPurpose: Int]
}

struct WeeklyLogSummary {
    let weekStart: Date
    let dailySummaries: [DailyLogSummary]
    let totalDurationSec: Int
    let totalVolumeKg: Double
}

enum TrainingLogAnalytics {
    static func dailySummaries(from logs: [TrainingLog], calendar: Calendar = .current) -> [DailyLogSummary] {
        let groups = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.date)
        }

        let summaries: [DailyLogSummary] = groups.map { date, logs in
            let duration = logs.reduce(0) { $0 + $1.sessionDurationSec }
            let volume = logs.reduce(0) { $0 + trainingVolume(for: $1) }
            let purposeCounts = logs.reduce(into: [TrainingPurpose: Int]()) { partialResult, log in
                partialResult[log.purpose, default: 0] += 1
            }
            return DailyLogSummary(
                date: date,
                logs: logs,
                totalDurationSec: duration,
                totalVolumeKg: volume,
                purposeCounts: purposeCounts
            )
        }

        return summaries.sorted { $0.date < $1.date }
    }

    static func weeklySummaries(from logs: [TrainingLog], calendar: Calendar = .current) -> [WeeklyLogSummary] {
        let daily = dailySummaries(from: logs, calendar: calendar)
        let groupedByWeek = Dictionary(grouping: daily) { summary in
            startOfWeek(for: summary.date, calendar: calendar)
        }

        let weeklySummaries: [WeeklyLogSummary] = groupedByWeek.compactMap { weekStart, summaries in
            guard let weekStart else { return nil }
            let sortedDaily = summaries.sorted { $0.date < $1.date }
            let duration = sortedDaily.reduce(0) { $0 + $1.totalDurationSec }
            let volume = sortedDaily.reduce(0) { $0 + $1.totalVolumeKg }
            return WeeklyLogSummary(
                weekStart: weekStart,
                dailySummaries: sortedDaily,
                totalDurationSec: duration,
                totalVolumeKg: volume
            )
        }

        return weeklySummaries.sorted { $0.weekStart < $1.weekStart }
    }

    private static func trainingVolume(for log: TrainingLog) -> Double {
        log.exercises.reduce(0) { current, exercise in
            current + exercise.sets.reduce(0) { setTotal, set in
                guard !set.isWarmup,
                      let weight = set.weightKg,
                      let reps = set.reps else { return setTotal }
                return setTotal + (weight * Double(reps))
            }
        }
    }

    private static func startOfWeek(for date: Date, calendar: Calendar) -> Date? {
        var calendar = calendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
    }
}
