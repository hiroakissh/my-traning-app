//
import SwiftUI
import SwiftData

@main
struct my_traning_appApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [TrainingLog.self, TrainingCondition.self, TrainingExercise.self, TrainingSet.self])
    }
}
