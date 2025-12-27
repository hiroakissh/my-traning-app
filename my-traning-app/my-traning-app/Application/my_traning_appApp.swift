//
//  my_traning_appApp.swift
//  my-traning-app
//
//  Created by HiroakiSaito on 2025/08/31.
//

import SwiftUI
import SwiftData

@main
struct my_traning_appApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainingLog.self,
            TrainingExercise.self,
            TrainingSet.self,
            TrainingCondition.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: [
                    TrainingLog.self,
                    TrainingCondition.self,
                    TrainingExercise.self,
                    TrainingSet.self,
                    ActivePlan.self
                ])
        }
        .modelContainer(sharedModelContainer)
    }
}
