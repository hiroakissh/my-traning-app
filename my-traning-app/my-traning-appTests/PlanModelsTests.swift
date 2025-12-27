import XCTest
@testable import my_traning_app

final class PlanModelsTests: XCTestCase {

    func test_planMetric_progressClampsBetweenZeroAndOne() {
        let metric = PlanMetric(name: "重量", unit: "kg", currentValue: 120, targetValue: 100, trend: .upward)
        XCTAssertEqual(metric.progressRate, 1.0)

        let underflowMetric = PlanMetric(name: "重量", unit: "kg", currentValue: -10, targetValue: 100, trend: .downward)
        XCTAssertEqual(underflowMetric.progressRate, 0.0)

        let zeroTargetMetric = PlanMetric(name: "重量", unit: "kg", currentValue: 10, targetValue: 0, trend: .steady)
        XCTAssertEqual(zeroTargetMetric.progressRate, 0.0)
    }

    func test_planProgress_overallRateUsesAverageOfMetrics() {
        let metrics = [
            PlanMetric(name: "重量", unit: "kg", currentValue: 50, targetValue: 100, trend: .upward), // 0.5
            PlanMetric(name: "回数", unit: "reps", currentValue: 30, targetValue: 60, trend: .steady) // 0.5
        ]
        let progress = PlanProgress(streakDays: 5, completedMilestones: 1, totalMilestones: 3, metrics: metrics)

        XCTAssertEqual(progress.overallRate, 0.5)
        XCTAssertEqual(progress.progressedMetricsCount, 2)
    }

    func test_planProgress_handlesEmptyMetrics() {
        let progress = PlanProgress(streakDays: 0, completedMilestones: 0, totalMilestones: 0, metrics: [])
        XCTAssertEqual(progress.overallRate, 0.0)
        XCTAssertEqual(progress.progressedMetricsCount, 0)
    }
}
