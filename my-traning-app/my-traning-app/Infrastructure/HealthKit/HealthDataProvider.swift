import Foundation

protocol HealthDataProviding {
    func requestAuthorization() async throws
    func fetchSnapshot(since start: Date) async throws -> HealthDataSnapshot
}

struct MockHealthDataProvider: HealthDataProviding {
    func requestAuthorization() async throws {
        // モックのため追加処理なし
    }

    func fetchSnapshot(since start: Date) async throws -> HealthDataSnapshot {
        let end = Date()
        let activeEnergy: Double = 320
        let basalEnergy: Double = 130
        let distance: Double = 3.2
        let stepCount: Int = 4_200
        let averageHeartRate: Double = 128
        let restingHeartRate: Double = 58
        let vo2Max: Double = 42

        return HealthDataSnapshot(
            start: start,
            end: end,
            averageHeartRate: averageHeartRate,
            restingHeartRate: restingHeartRate,
            activeEnergyBurned: activeEnergy,
            basalEnergyBurned: basalEnergy,
            distanceWalkingRunning: distance,
            stepCount: stepCount,
            vo2Max: vo2Max
        )
    }
}
