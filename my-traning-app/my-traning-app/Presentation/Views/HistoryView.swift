import SwiftUI
import Charts

// ダミーデータ
struct TrainingHistoryItem: Identifiable {
    let id = UUID()
    let date: String
    let title: String
    let summary: String
}

let dummyHistory: [TrainingHistoryItem] = [
    TrainingHistoryItem(date: "2025/08/31", title: "胸の日", summary: "ベンチプレス, ダンベルフライ"),
    TrainingHistoryItem(date: "2025/08/29", title: "脚の日", summary: "スクワット, レッグプレス"),
    TrainingHistoryItem(date: "2025/08/28", title: "背中の日", summary: "デッドリフト, 懸垂"),
]

struct HistoryView: View {
    @State private var selectedMode = 0
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppLayout.grid * 2) {
                        HudSectionCard(title: "表示モード", subtitle: "リスト/カレンダー/分析を切り替え") {
                            Picker("表示モード", selection: $selectedMode) {
                                Text("リスト").tag(0)
                                Text("カレンダー").tag(1)
                                Text("分析").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .tint(AppColors.primary)
                        }

                        switch selectedMode {
                        case 0:
                            ListView()
                        case 1:
                            CalendarView(selectedDate: $selectedDate)
                        case 2:
                            ChartView()
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, AppLayout.grid * 2.5)
                    .padding(.vertical, AppLayout.grid * 3)
                }
            }
            .navigationTitle("履歴")
        }
    }
}

// MARK: - Subviews

private struct ListView: View {
    var body: some View {
        HudSectionCard(title: "ログ一覧") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
                ForEach(Array(dummyHistory.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                        Text(item.date)
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                        Text(item.title)
                            .font(AppTypography.body(17, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(item.summary)
                            .font(AppTypography.body(15))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if index < dummyHistory.count - 1 {
                        Divider()
                            .overlay(AppColors.divider)
                    }
                }
            }
        }
    }
}

private struct CalendarView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HudSectionCard(title: "カレンダー", subtitle: "日付をタップして記録を表示") {
            DatePicker("日付を選択", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(AppColors.primary)
        }
    }
}

private struct ChartView: View {
    // ダミーのグラフデータ
    let chartData: [(String, Int)] = [
        ("6月", 55), ("7月", 58), ("8月", 60)
    ]
    
    var body: some View {
        HudSectionCard(title: "ベンチプレス 重量推移 (kg)", subtitle: "淡いグローで推移を俯瞰") {
            Chart {
                ForEach(chartData, id: \.0) { month, weight in
                    BarMark(
                        x: .value("月", month),
                        y: .value("重量(kg)", weight)
                    )
                    .foregroundStyle(AppColors.primary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(minHeight: 180)
        }
    }
}


#Preview {
    HistoryView()
}
