//
import SwiftUI
import SwiftData

@main
struct my_traning_appApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainingLog.self,
            TrainingExercise.self,
            TrainingSet.self,
            TrainingCondition.self,
            ActivePlan.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
