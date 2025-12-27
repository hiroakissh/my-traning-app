import XCTest
@testable import my_traning_app

final class TrainingLogAnalyticsTests: XCTestCase {

    func test_dailySummaries_groupByDateAndCalculateVolume() throws {
        let calendar = Calendar(identifier: .gregorian)
        let log1 = makeLog(dateComponents: DateComponents(year: 2024, month: 1, day: 1), sessionDurationSec: 1800, purpose: .refresh, exercises: [
            makeExercise(name: "Bench", sets: [
                makeSet(order: 1, weightKg: 60, reps: 10),
                makeSet(order: 2, weightKg: 60, reps: 8, isWarmup: true) // 除外
            ])
        ])

        let log2 = makeLog(dateComponents: DateComponents(year: 2024, month: 1, day: 1), sessionDurationSec: 1200, purpose: .hypertrophy, exercises: [
            makeExercise(name: "Run", category: .cardio, sets: [
                makeSet(order: 1, durationSec: 900)
            ])
        ])

        let log3 = makeLog(dateComponents: DateComponents(year: 2024, month: 1, day: 2), sessionDurationSec: 600, exercises: [])

        let summaries = TrainingLogAnalytics.dailySummaries(from: [log1, log2, log3], calendar: calendar)
        XCTAssertEqual(summaries.count, 2)

        let day1 = try XCTUnwrap(summaries.first { calendar.isDate($0.date, inSameDayAs: log1.date) })
        XCTAssertEqual(day1.totalDurationSec, 3000)
        XCTAssertEqual(day1.totalVolumeKg, 600) // 60*10 のみ
        XCTAssertEqual(day1.purposeCounts[log1.purpose], 1)
        XCTAssertEqual(day1.purposeCounts[log2.purpose], 1)

        let day2 = try XCTUnwrap(summaries.first { calendar.isDate($0.date, inSameDayAs: log3.date) })
        XCTAssertEqual(day2.totalDurationSec, 600)
        XCTAssertEqual(day2.totalVolumeKg, 0)
    }

    func test_weeklySummaries_groupByWeekStart() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday start
        let weekStart = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let log1 = makeLog(dateComponents: DateComponents(year: 2024, month: 1, day: 1), sessionDurationSec: 900, exercises: [])
        let log2 = makeLog(dateComponents: DateComponents(year: 2024, month: 1, day: 7), sessionDurationSec: 600, exercises: [])
        let log3 = makeLog(dateComponents: DateComponents(year: 2024, month: 1, day: 10), sessionDurationSec: 1800, exercises: [
            makeExercise(name: "Squat", sets: [makeSet(order: 1, weightKg: 80, reps: 5)])
        ])

        let weekly = TrainingLogAnalytics.weeklySummaries(from: [log1, log2, log3], calendar: calendar)
        XCTAssertEqual(weekly.count, 2)

        let firstWeek = try XCTUnwrap(weekly.first { calendar.isDate($0.weekStart, inSameDayAs: weekStart) })
        XCTAssertEqual(firstWeek.totalDurationSec, 1500)

        let secondWeek = try XCTUnwrap(weekly.first { calendar.isDate($0.weekStart, inSameDayAs: calendar.date(from: DateComponents(year: 2024, month: 1, day: 8))!) })
        XCTAssertEqual(secondWeek.totalVolumeKg, 400) // 80*5
        XCTAssertEqual(secondWeek.dailySummaries.count, 1)
    }

    func test_weeklySummaries_respectsCalendarTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let date = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: 2024, month: 1, day: 1, hour: 0, minute: 30)))
        let log = TrainingLog(date: date, sessionDurationSec: 600, purpose: .refresh, source: .manual, exercises: [])

        let weekly = TrainingLogAnalytics.weeklySummaries(from: [log], calendar: calendar)
        XCTAssertEqual(weekly.count, 1)

        let weekStart = try XCTUnwrap(weekly.first?.weekStart)
        let expectedWeekStart = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: 2024, month: 1, day: 1)))

        XCTAssertTrue(calendar.isDate(weekStart, inSameDayAs: expectedWeekStart))
    }

    // MARK: - Helpers

    private func makeLog(
        dateComponents: DateComponents,
        sessionDurationSec: Int,
        purpose: TrainingPurpose = .refresh,
        exercises: [TrainingExercise]
    ) -> TrainingLog {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: dateComponents)!
        return TrainingLog(
            date: date,
            sessionDurationSec: sessionDurationSec,
            purpose: purpose,
            source: .manual,
            exercises: exercises
        )
    }

    private func makeExercise(name: String, bodyPart: BodyPart = .chest, category: ExerciseCategory = .strength, sets: [TrainingSet]) -> TrainingExercise {
        TrainingExercise(name: name, bodyPart: bodyPart, category: category, sets: sets)
    }

    private func makeSet(order: Int, weightKg: Double? = nil, reps: Int? = nil, durationSec: Int? = nil, isWarmup: Bool = false) -> TrainingSet {
        TrainingSet(order: order, weightKg: weightKg, reps: reps, durationSec: durationSec, isWarmup: isWarmup, isBodyweight: weightKg == nil)
    }
}
