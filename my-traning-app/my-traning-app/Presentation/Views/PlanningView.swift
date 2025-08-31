import SwiftUI

// ダミーデータ
struct PlanItem: Identifiable {
    let id = UUID()
    let title: String
    let goal: String
    let duration: String
}

let longTermPlan = PlanItem(title: "長期プラン", goal: "ベンチプレス100kg達成", duration: "2025/09/01 - 2026/08/31")
let midTermPlan = PlanItem(title: "中期プラン", goal: "ベンチプレス80kg達成", duration: "2025/09/01 - 2025/11/30")
let shortTermPlan = PlanItem(title: "短期プラン", goal: "ベンチプレス65kg達成", duration: "2025/09/01 - 2025/09/30")

struct PlanningView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("長期プラン").font(.title2).bold()) {
                    PlanRow(plan: longTermPlan)
                }
                
                Section(header: Text("中期プラン").font(.title2).bold()) {
                    PlanRow(plan: midTermPlan)
                }
                
                Section(header: Text("短期プラン").font(.title2).bold()) {
                    PlanRow(plan: shortTermPlan)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("プランニング")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("再生成")
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

// MARK: - Subviews

private struct PlanRow: View {
    let plan: PlanItem
    
    var body: some View {
        NavigationLink(destination: PlanDetailView(plan: plan)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.goal)
                    .font(.headline)
                Text(plan.duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Detail View

struct PlanDetailView: View {
    let plan: PlanItem
    
    var body: some View {
        VStack {
            Text(plan.title).font(.largeTitle)
            Text(plan.goal).font(.title2)
            Text(plan.duration).font(.headline)
            // ここにプランの詳細なスケジュール（カレンダーなど）が表示される
            Spacer()
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    PlanningView()
}
