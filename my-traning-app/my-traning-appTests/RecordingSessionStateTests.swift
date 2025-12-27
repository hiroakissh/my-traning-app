import XCTest
@testable import my_traning_app

final class RecordingSessionStateTests: XCTestCase {

    func test_progressCalculationsRespectTargets() {
        let targets = RecordingSessionTargets(time: 1800, distance: 5000, activeCalories: 400, averageHeartRate: 140)
        var state = RecordingSessionState(elapsed: 900, distance: 2500, activeCalories: 120, heartRateSamples: [130, 150], targets: targets)

        XCTAssertEqual(state.timeProgress, 0.5)
        XCTAssertEqual(state.distanceProgress, 0.5)
        XCTAssertEqual(state.calorieProgress, 0.3)
        XCTAssertEqual(state.heartRateProgress, 1.0) // 平均140に到達しているためクランプ
    }

    func test_progressReturnsNilWhenTargetsMissing() {
        let state = RecordingSessionState(elapsed: 900, distance: 1000, activeCalories: 120, heartRateSamples: [], targets: RecordingSessionTargets())

        XCTAssertNil(state.timeProgress)
        XCTAssertNil(state.distanceProgress)
        XCTAssertNil(state.calorieProgress)
        XCTAssertNil(state.heartRateProgress)
        XCTAssertNil(state.averageHeartRate)
    }

    func test_heartRateProgressUsesAverageAndClamps() {
        var state = RecordingSessionState(elapsed: 0, distance: 0, activeCalories: 0, heartRateSamples: [100, 110, 90], targets: RecordingSessionTargets(averageHeartRate: 200))
        XCTAssertEqual(state.averageHeartRate, 100)
        XCTAssertEqual(state.heartRateProgress, 0.5)

        state.heartRateSamples.append(contentsOf: [190, 210])
        XCTAssertEqual(state.averageHeartRate, 140)
        XCTAssertEqual(state.heartRateProgress, 0.7)
    }
}
