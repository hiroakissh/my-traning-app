import SwiftUI
import SwiftData

struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }

            RecordingView()
                .tabItem {
                    Label("記録", systemImage: "plus.circle.fill")
                }

            PlanningView()
                .tabItem {
                    Label("プラン", systemImage: "list.bullet.clipboard.fill")
                }
        }
        .hudBackground()
        .tint(AppColors.primary)
    }
}

#Preview {
    MainView()
        .modelContainer(
            for: [
                ActivePlan.self,
                TrainingLog.self,
                TrainingExercise.self,
                TrainingSet.self,
                TrainingCondition.self
            ] as [any PersistentModel.Type],
            inMemory: true
        )
}
