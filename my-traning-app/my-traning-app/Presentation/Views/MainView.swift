import SwiftUI

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

            PlanningView()
                .tabItem {
                    Label("プラン", systemImage: "list.bullet.clipboard.fill")
                }
        }
    }
}

#Preview {
    MainView()
}
