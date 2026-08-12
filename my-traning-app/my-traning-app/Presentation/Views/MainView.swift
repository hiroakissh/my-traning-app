import SwiftUI
import SwiftData

struct MainView: View {
    @EnvironmentObject private var watchConnectivity: WatchConnectivityService
    @Environment(\.modelContext) private var modelContext

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
        .applyHudTabBarChrome()
        .task {
            watchConnectivity.processPendingEvents(using: modelContext)
        }
        .onChange(of: watchConnectivity.eventRevision) { _, _ in
            watchConnectivity.processPendingEvents(using: modelContext)
        }
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
                TrainingCondition.self,
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
            ] as [any PersistentModel.Type],
            inMemory: true
        )
        .environmentObject(WatchConnectivityService())
}

private extension View {
    @ViewBuilder
    func applyHudTabBarChrome() -> some View {
        #if os(iOS)
        self
            .toolbarBackground(AppColors.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
        #else
        self
        #endif
    }
}
