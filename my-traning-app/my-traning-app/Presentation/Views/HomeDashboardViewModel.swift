import Foundation
import SwiftUI

struct HomeDashboardSnapshot {
    let dailyGoalKcal: Double
    let burnedKcal: Double
    let progressRate: Double
    let distanceKm: Double?
    let averageHeartRate: Double?
    let latestWorkoutTitle: String?
    let latestWorkoutSubtitle: String?
    let latestDurationMinutes: Int?
}

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published var healthSnapshot: HealthDataSnapshot?
    @Published var isLoadingHealth: Bool = false
    @Published var healthErrorMessage: String?

    private let healthProvider: HealthDataProviding
    private let calendar: Calendar
    let dailyGoalKcal: Double

    init(
        healthProvider: HealthDataProviding = HealthDataProviderFactory.make(),
        calendar: Calendar = .current,
        dailyGoalKcal: Double = 1650
    ) {
        self.healthProvider = healthProvider
        self.calendar = calendar
        self.dailyGoalKcal = dailyGoalKcal
    }

    func refreshHealthData() async {
        isLoadingHealth = true
        defer { isLoadingHealth = false }

        do {
            try await healthProvider.requestAuthorization()
            let startOfDay = calendar.startOfDay(for: Date())
            let snapshot = try await healthProvider.fetchSnapshot(since: startOfDay)
            healthSnapshot = snapshot
            healthErrorMessage = nil
        } catch {
            healthSnapshot = nil
            healthErrorMessage = mapHealthError(error)
        }
    }

    func dashboard(logs: [TrainingLog]) -> HomeDashboardSnapshot {
        let latestLog = logs.sorted { $0.date > $1.date }.first
        let burned = healthSnapshot?.totalEnergyBurned ?? 0
        let progress = dailyGoalKcal > 0 ? min(max(burned / dailyGoalKcal, 0), 1) : 0

        let exerciseNames = latestLog?.exercises
            .map(\.name)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(2)
            .joined(separator: "・")

        let subtitleParts: [String?] = [
            latestLog?.purpose.displayName,
            exerciseNames
        ]

        return HomeDashboardSnapshot(
            dailyGoalKcal: dailyGoalKcal,
            burnedKcal: burned,
            progressRate: progress,
            distanceKm: healthSnapshot?.distanceWalkingRunning,
            averageHeartRate: healthSnapshot?.averageHeartRate,
            latestWorkoutTitle: latestLog?.date.formatted(date: .abbreviated, time: .omitted),
            latestWorkoutSubtitle: subtitleParts.compactMap { $0 }.joined(separator: " ・ "),
            latestDurationMinutes: latestLog.map { $0.sessionDurationSec / 60 }
        )
    }

    func makeAssistantContext(query: String, logs: [TrainingLog], activePlan: ActivePlan?) -> AIAssistantContext {
        AIAssistantContext(
            userQuery: query,
            activePlan: activePlan,
            recentLogs: logs,
            healthSnapshot: healthSnapshot,
            dailyGoalKcal: dailyGoalKcal
        )
    }

    private func mapHealthError(_ error: Error) -> String {
        if let hkError = error as? HealthDataProviderError {
            switch hkError {
            case .healthDataNotAvailable:
                return "このデバイスではヘルスデータが利用できません。"
            case .authorizationFailed, .authorizationDeniedOrRestricted:
                return "ヘルスデータの読み取りが許可されませんでした。設定を確認してください。"
            case .typeUnavailable:
                return "必要なヘルスデータにアクセスできません。"
            }
        }

        return "ヘルスデータの取得に失敗しました。時間を置いて再度お試しください。"
    }
}
