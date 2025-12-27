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
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainingLog.self,
            TrainingCondition.self,
            TrainingExercise.self,
            TrainingSet.self
        ])

        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isRunningTests)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
