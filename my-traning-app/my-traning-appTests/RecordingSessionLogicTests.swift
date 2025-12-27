import XCTest
@testable import my_traning_app

final class RecordingSessionLogicTests: XCTestCase {

    func test_startValidationRequiresPurposeAndMenuCount() {
        let validator = RecordingSessionValidator()

        let missingPurpose = validator.validateForStart(purpose: nil, selectedMenuCount: 2)
        XCTAssertFalse(missingPurpose.isValid)
        XCTAssertEqual(missingPurpose.message, "目標タイプを選択してください。")

        let insufficientMenu = validator.validateForStart(purpose: .hypertrophy, selectedMenuCount: 1)
        XCTAssertFalse(insufficientMenu.isValid)
        XCTAssertEqual(insufficientMenu.message, "筋肥大/調整では最低2件のメニューを選択してください。")

        let valid = validator.validateForStart(purpose: .hypertrophy, selectedMenuCount: 2)
        XCTAssertTrue(valid.isValid)
        XCTAssertNil(valid.message)
    }

    func test_finishValidationRequiresElapsedTimeForDiet() {
        let validator = RecordingSessionValidator()

        let notStarted = validator.validateForFinish(purpose: .diet, selectedMenuCount: 2, elapsedSeconds: 500, hasStarted: false)
        XCTAssertFalse(notStarted.isValid)
        XCTAssertEqual(notStarted.message, "計測を開始してください。")

        let insufficient = validator.validateForFinish(purpose: .diet, selectedMenuCount: 2, elapsedSeconds: 500, hasStarted: true)
        XCTAssertFalse(insufficient.isValid)
        XCTAssertEqual(insufficient.message, "減量では10分以上（600秒）の計測が必要です。")

        let valid = validator.validateForFinish(purpose: .diet, selectedMenuCount: 2, elapsedSeconds: 600, hasStarted: true)
        XCTAssertTrue(valid.isValid)
        XCTAssertNil(valid.message)
    }

    func test_finishValidationRequiresTimerStart() {
        let validator = RecordingSessionValidator()

        let result = validator.validateForFinish(purpose: .tune, selectedMenuCount: 2, elapsedSeconds: 0, hasStarted: false)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "計測を開始してください。")
    }

    func test_timerStateAccumulatesAndResets() {
        var timerState = RecordingTimerState()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        timerState.start(now: base)
        timerState.tick(now: base.addingTimeInterval(5))
        XCTAssertEqual(timerState.elapsedSeconds, 5)
        XCTAssertTrue(timerState.isRunning)
        XCTAssertEqual(timerState.startTime, base)

        timerState.pause(now: base.addingTimeInterval(8))
        XCTAssertEqual(timerState.elapsedSeconds, 8)
        XCTAssertFalse(timerState.isRunning)

        timerState.resume(now: base.addingTimeInterval(10))
        timerState.tick(now: base.addingTimeInterval(15))
        XCTAssertEqual(timerState.elapsedSeconds, 13)

        timerState.stop(now: base.addingTimeInterval(20))
        XCTAssertEqual(timerState.elapsedSeconds, 18)
        XCTAssertEqual(timerState.endTime, base.addingTimeInterval(20))

        timerState.reset()
        XCTAssertEqual(timerState.elapsedSeconds, 0)
        XCTAssertNil(timerState.startTime)
        XCTAssertNil(timerState.endTime)
        XCTAssertFalse(timerState.isRunning)
    }

    func test_timeFormatterProducesReadableStrings() {
        XCTAssertEqual(RecordingTimeFormatter.string(from: 65), "01:05")
        XCTAssertEqual(RecordingTimeFormatter.string(from: 600), "10:00")
        XCTAssertEqual(RecordingTimeFormatter.string(from: 3661), "01:01:01")
    }

    func test_logBuilderCreatesTrainingLogFromSelection() {
        var timerState = RecordingTimerState()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        timerState.start(now: start)
        timerState.tick(now: start.addingTimeInterval(600))
        timerState.stop(now: start.addingTimeInterval(600))

        let menu = WorkoutMenuItem(name: "ベンチプレス", description: "胸の基本種目", equipment: "バーベル")
        let builder = RecordingSessionLogBuilder()

        let log = builder.makeLog(
            purpose: .diet,
            selectedMenus: [menu],
            timerState: timerState,
            date: start
        )

        XCTAssertEqual(log.purpose, .diet)
        XCTAssertEqual(log.source, .timer)
        XCTAssertEqual(log.sessionDurationSec, 600)
        XCTAssertEqual(log.startTime, start)
        XCTAssertEqual(log.endTime, start.addingTimeInterval(600))
        XCTAssertEqual(Calendar.current.startOfDay(for: log.date), Calendar.current.startOfDay(for: start))
        XCTAssertEqual(log.exercises.count, 1)
        XCTAssertEqual(log.exercises.first?.name, "ベンチプレス")
        XCTAssertEqual(log.exercises.first?.category, .strength)
        XCTAssertEqual(log.exercises.first?.bodyPart, .other)
        XCTAssertTrue(log.exercises.first?.sets.isEmpty ?? false)
    }

    func test_logBuilderUsesActualFinishTimeWhenPaused() {
        var timerState = RecordingTimerState()
        let start = Date(timeIntervalSince1970: 1_700_100_000) // 2023-11-14T06:00:00Z 相当

        timerState.start(now: start)
        timerState.tick(now: start.addingTimeInterval(300)) // 5分稼働
        timerState.pause(now: start.addingTimeInterval(300))

        // ここで10分間停止していたと仮定（経過時間に加算しない）
        timerState.resume(now: start.addingTimeInterval(900))
        timerState.tick(now: start.addingTimeInterval(1200)) // 再開後5分稼働
        timerState.stop(now: start.addingTimeInterval(1200)) // 実際の終了はスタートから20分後

        let builder = RecordingSessionLogBuilder()
        let log = builder.makeLog(
            purpose: .refresh,
            selectedMenus: [],
            timerState: timerState,
            date: start
        )

        XCTAssertEqual(log.sessionDurationSec, 600) // 稼働時間10分のみをカウント
        XCTAssertEqual(log.startTime, start)
        XCTAssertEqual(log.endTime, start.addingTimeInterval(1200)) // 実際の終了時刻を保持
    }
}
