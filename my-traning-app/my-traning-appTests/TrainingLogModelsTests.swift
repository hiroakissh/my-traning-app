import XCTest
@testable import my_traning_app

final class TrainingLogModelsTests: XCTestCase {
    func testCardioMetricsCalculatesPace() {
        let metrics = CardioMetrics(distanceInKilometers: 5.0, durationInSeconds: 1500)

        XCTAssertEqual(metrics.pacePerKilometer, 300, accuracy: 0.1)
        XCTAssertEqual(metrics.formattedPace, "5:00 /km")
    }

    func testHealthDataSnapshotAggregatesMetrics() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(1800)
        let snapshot = HealthDataSnapshot(
            start: start,
            end: end,
            averageHeartRate: 128,
            restingHeartRate: 58,
            activeEnergyBurned: 320,
            basalEnergyBurned: 130,
            distanceWalkingRunning: 3.2,
            stepCount: 4_200,
            vo2Max: 42.0
        )

        XCTAssertEqual(snapshot.totalEnergyBurned, 450)

        let metrics = snapshot.availableMetrics
        XCTAssertEqual(metrics["平均心拍数"], "128 bpm")
        XCTAssertEqual(metrics["消費カロリー"], "450 kcal")
        XCTAssertEqual(metrics["歩数"], "4200 steps")
        XCTAssertEqual(metrics["距離"], "3.2 km")
    }
}
