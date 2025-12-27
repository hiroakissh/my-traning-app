import XCTest
@testable import my_traning_app

final class TrainingHistoryFilterTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    override func tearDown() {
        calendar = nil
        super.tearDown()
    }

    func test_makeItems_buildsSummaryFromTrainingLog() {
        // Given
        let log = makeLog(
            date: makeDate(year: 2024, month: 8, day: 30),
            purpose: .hypertrophy,
            note: "フォーム確認と肩のケア"
        )
        log.exercises = [
            makeExercise(
                name: "ベンチプレス",
                category: .strength,
                bodyPart: .chest,
                sets: [makeSet(order: 1), makeSet(order: 2)]
            ),
            makeExercise(
                name: "エアロバイク",
                category: .cardio,
                bodyPart: .legs,
                sets: [makeSet(order: 1)]
            )
        ]

        // When
        let items = TrainingHistoryBuilder.makeItems(from: [log], calendar: calendar)

        // Then
        let item = try! XCTUnwrap(items.first)
        XCTAssertEqual(item.title, "ベンチプレス")
        XCTAssertEqual(item.totalSets, 3)
        XCTAssertEqual(item.categories, Set([.strength, .cardio]))
        XCTAssertEqual(item.bodyParts, Set([.chest, .legs]))
        XCTAssertTrue(item.subtitle.contains("筋肥大"))
        XCTAssertTrue(item.searchableText.contains("フォーム確認"))
    }

    func test_filter_bySearchTextMatchesExercisesAndNote() {
        // Given
        let targetLog = makeLog(
            date: makeDate(year: 2024, month: 9, day: 1),
            purpose: .tune,
            note: "腰の調整でフォーム軽め"
        )
        targetLog.exercises = [
            makeExercise(name: "デッドリフト", category: .strength, bodyPart: .back, sets: [makeSet(order: 1)])
        ]

        let otherLog = makeLog(
            date: makeDate(year: 2024, month: 9, day: 2),
            purpose: .refresh,
            note: "有酸素中心"
        )
        otherLog.exercises = [
            makeExercise(name: "スピンバイク", category: .cardio, bodyPart: .legs, sets: [makeSet(order: 1)])
        ]

        let items = TrainingHistoryBuilder.makeItems(from: [targetLog, otherLog], calendar: calendar)

        // When
        let searchByExercise = TrainingHistoryFilter.apply(
            items: items,
            searchText: "デッド",
            category: nil,
            date: nil,
            calendar: calendar
        )

        let searchByNote = TrainingHistoryFilter.apply(
            items: items,
            searchText: "腰の調整",
            category: nil,
            date: nil,
            calendar: calendar
        )

        // Then
        XCTAssertEqual(searchByExercise.count, 1)
        XCTAssertEqual(searchByExercise.first?.title, "デッドリフト")

        XCTAssertEqual(searchByNote.count, 1)
        XCTAssertEqual(searchByNote.first?.title, "デッドリフト")
    }

    func test_filter_combinesCategoryAndDate() {
        // Given
        let dateToMatch = makeDate(year: 2024, month: 8, day: 15)
        let cardioLog = makeLog(date: dateToMatch, purpose: .refresh)
        cardioLog.exercises = [
            makeExercise(name: "ジョグ", category: .cardio, bodyPart: .legs, sets: [makeSet(order: 1)])
        ]

        let strengthLog = makeLog(date: makeDate(year: 2024, month: 8, day: 16), purpose: .hypertrophy)
        strengthLog.exercises = [
            makeExercise(name: "スクワット", category: .strength, bodyPart: .legs, sets: [makeSet(order: 1)])
        ]

        let items = TrainingHistoryBuilder.makeItems(from: [cardioLog, strengthLog], calendar: calendar)

        // When
        let filtered = TrainingHistoryFilter.apply(
            items: items,
            searchText: "",
            category: .cardio,
            date: dateToMatch,
            calendar: calendar
        )

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "ジョグ")
        XCTAssertTrue(filtered.first?.categories.contains(.cardio) ?? false)
    }

    // MARK: - Helpers

    private func makeLog(date: Date, purpose: TrainingPurpose, note: String? = nil) -> TrainingLog {
        TrainingLog(
            date: date,
            sessionDurationSec: 1800,
            purpose: purpose,
            source: .manual,
            exercises: [],
            note: note
        )
    }

    private func makeExercise(
        name: String,
        category: ExerciseCategory,
        bodyPart: BodyPart,
        sets: [TrainingSet]
    ) -> TrainingExercise {
        TrainingExercise(
            name: name,
            bodyPart: bodyPart,
            category: category,
            sets: sets
        )
    }

    private func makeSet(order: Int) -> TrainingSet {
        TrainingSet(order: order, weightKg: 50, reps: 8)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day)
        return calendar.date(from: components)!
    }
}
