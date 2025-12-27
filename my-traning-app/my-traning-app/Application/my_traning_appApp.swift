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
    }
}
