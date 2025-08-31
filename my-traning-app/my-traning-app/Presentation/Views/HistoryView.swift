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
            VStack {
                Picker("表示モード", selection: $selectedMode) {
                    Text("リスト").tag(0)
                    Text("カレンダー").tag(1)
                    Text("分析").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 表示モードに応じてViewを切り替え
                switch selectedMode {
                case 0:
                    ListView()
                case 1:
                    CalendarView(selectedDate: $selectedDate)
                case 2:
                    ChartView()
                default:
                    Text("Error")
                }
                
                Spacer()
            }
            .navigationTitle("履歴")
        }
    }
}

// MARK: - Subviews

private struct ListView: View {
    var body: some View {
        List(dummyHistory) { item in
            VStack(alignment: .leading) {
                Text(item.date).font(.caption).foregroundColor(.secondary)
                Text(item.title).font(.headline)
                Text(item.summary).font(.subheadline)
            }
        }
    }
}

private struct CalendarView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        // iOS 16.0+ で利用可能な GraphicalDatePickerStyle
        DatePicker("日付を選択", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(.graphical)
            .padding()
    }
}

private struct ChartView: View {
    // ダミーのグラフデータ
    let chartData: [(String, Int)] = [
        ("6月", 55), ("7月", 58), ("8月", 60)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("ベンチプレス 重量推移 (kg)")
                .font(.headline)
                .padding()
            
            Chart {
                ForEach(chartData, id: \.0) { month, weight in
                    BarMark(
                        x: .value("月", month),
                        y: .value("重量(kg)", weight)
                    )
                }
            }
            .padding()
        }
    }
}


#Preview {
    HistoryView()
}
