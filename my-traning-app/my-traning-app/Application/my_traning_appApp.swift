//
import SwiftUI
import SwiftData

@main
struct my_traning_appApp: App {
    @StateObject private var watchConnectivity = WatchConnectivityService()

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainingLog.self,
            TrainingExercise.self,
            TrainingSet.self,
            TrainingCondition.self,
            ActivePlan.self,
            DailyCheckIn.self,
            DailyRecommendation.self,
            PlannedExercise.self,
            AlternativePlan.self,
            WorkoutSession.self,
            WorkoutSessionExercise.self,
            PlannedSet.self,
            ActualSet.self,
            UserGoal.self,
            WeeklyReview.self
        ])

        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isRunningTests)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(watchConnectivity)
        }
        .modelContainer(sharedModelContainer)
    }
}
