import Foundation
import HealthKit

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

enum HealthDataProviderError: Error {
    case healthDataNotAvailable
    case authorizationFailed
    case typeUnavailable(identifier: HKQuantityTypeIdentifier)
}

@available(iOS 17.0, *)
final class LiveHealthDataProvider: HealthDataProviding {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthDataProviderError.healthDataNotAvailable
        }

        let readTypes = Set([
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKQuantityType.quantityType(forIdentifier: .vo2Max)
        ].compactMap { $0 })

        let success: Bool = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { isAuthorized, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: isAuthorized)
            }
        }

        guard success else {
            throw HealthDataProviderError.authorizationFailed
        }
    }

    func fetchSnapshot(since start: Date) async throws -> HealthDataSnapshot {
        let end = Date()

        async let averageHeartRate = fetchAverage(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let restingHeartRate = fetchAverage(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let activeEnergy = fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let basalEnergy = fetchSum(.basalEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let distance = fetchSum(.distanceWalkingRunning, unit: .meter(), start: start, end: end)
        async let steps = fetchSum(.stepCount, unit: .count(), start: start, end: end)
        async let vo2Max = fetchAverage(.vo2Max, unit: HKUnit(from: "mL/(kg*min)"), start: start, end: end)

        let snapshot = HealthDataSnapshot(
            start: start,
            end: end,
            averageHeartRate: try await averageHeartRate,
            restingHeartRate: try await restingHeartRate,
            activeEnergyBurned: try await activeEnergy,
            basalEnergyBurned: try await basalEnergy,
            distanceWalkingRunning: try await distance.map { $0 / 1000 }, // to km
            stepCount: try await steps.map { Int($0) },
            vo2Max: try await vo2Max
        )

        return snapshot
    }

    private func fetchAverage(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        try await fetchQuantity(identifier, unit: unit, start: start, end: end, options: .discreteAverage) { statistics in
            statistics.averageQuantity()
        }
    }

    private func fetchSum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        try await fetchQuantity(identifier, unit: unit, start: start, end: end, options: .cumulativeSum) { statistics in
            statistics.sumQuantity()
        }
    }

    private func fetchQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date,
        options: HKStatisticsOptions,
        extractor: @escaping (HKStatistics) -> HKQuantity?
    ) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthDataProviderError.typeUnavailable(identifier: identifier)
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let statistics, let quantity = extractor(statistics) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: quantity.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }
}

enum HealthDataProviderFactory {
    static func make() -> HealthDataProviding {
        if #available(iOS 17.0, *), HKHealthStore.isHealthDataAvailable() {
            return LiveHealthDataProvider()
        } else {
            return MockHealthDataProvider()
        }
    }
}
