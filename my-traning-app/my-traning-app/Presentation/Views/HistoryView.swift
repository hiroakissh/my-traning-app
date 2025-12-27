import SwiftData
import SwiftUI
import Charts

private enum HistoryDisplayMode: Int, CaseIterable {
    case list
    case calendar
    case analysis

    var title: String {
        switch self {
        case .list: return "リスト"
        case .calendar: return "カレンダー"
        case .analysis: return "分析"
        }
    }
}

struct HistoryView: View {
    @Environment(\.calendar) private var calendar
    @Query(sort: \TrainingLog.date, order: .reverse) private var logs: [TrainingLog]

    @State private var selectedMode: HistoryDisplayMode = .list
    @State private var searchText: String = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedDate: Date = Date()

    init() {}

    private var historyItems: [TrainingHistoryItem] {
        TrainingHistoryBuilder.makeItems(from: logs, calendar: calendar)
    }

    private var filteredItems: [TrainingHistoryItem] {
        TrainingHistoryFilter.apply(
            items: historyItems,
            searchText: searchText,
            category: selectedCategory,
            date: selectedMode == .calendar ? selectedDate : nil,
            calendar: calendar
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("表示モード", selection: $selectedMode) {
                    ForEach(HistoryDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedMode {
                case .list:
                    HistoryListView(
                        items: filteredItems,
                        searchText: $searchText,
                        selectedCategory: $selectedCategory
                    ) { item in
                        selectedDate = item.date
                        selectedMode = .calendar
                    }
                case .calendar:
                    HistoryCalendarView(
                        items: filteredItems,
                        selectedDate: $selectedDate,
                        searchText: $searchText,
                        selectedCategory: $selectedCategory
                    )
                case .analysis:
                    HistoryAnalysisView(
                        items: TrainingHistoryFilter.apply(
                            items: historyItems,
                            searchText: "",
                            category: selectedCategory,
                            date: nil,
                            calendar: calendar
                        ),
                        selectedCategory: $selectedCategory
                    )
                }
            }
            .navigationTitle("履歴")
            .onAppear(perform: initializeSelectedDate)
        }
    }

    private func initializeSelectedDate() {
        if let latestDate = logs.first?.date {
            selectedDate = latestDate
        }
    }
}

// MARK: - Subviews

private struct HistoryListView: View {
    let items: [TrainingHistoryItem]
    @Binding var searchText: String
    @Binding var selectedCategory: ExerciseCategory?
    let onSelect: (TrainingHistoryItem) -> Void

    var body: some View {
        List {
            if items.isEmpty {
                HistoryEmptyState(message: "表示できる記録がありません。検索条件を調整してください。")
            } else {
                ForEach(items) { item in
                    NavigationLink(destination: TrainingLogDetailView(log: item.log, item: item)) {
                        HistoryRow(item: item)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        onSelect(item)
                    })
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "種目名やメモで検索"
        )
        .toolbar {
            HistoryCategoryFilter(selectedCategory: $selectedCategory)
        }
    }
}

private struct HistoryCalendarView: View {
    let items: [TrainingHistoryItem]
    @Binding var selectedDate: Date
    @Binding var searchText: String
    @Binding var selectedCategory: ExerciseCategory?

    var body: some View {
        VStack {
            DatePicker("日付を選択", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)

            List {
                if items.isEmpty {
                    HistoryEmptyState(message: "選択した日に表示できる記録がありません。")
                } else {
                    ForEach(items) { item in
                        NavigationLink(destination: TrainingLogDetailView(log: item.log, item: item)) {
                            HistoryRow(item: item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "種目名やメモで検索"
        )
        .toolbar {
            HistoryCategoryFilter(selectedCategory: $selectedCategory)
        }
    }
}

private struct HistoryAnalysisView: View {
    let items: [TrainingHistoryItem]
    @Binding var selectedCategory: ExerciseCategory?

    private var monthlySessions: [MonthlySummary] {
        var grouped: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM"

        for item in items {
            let key = formatter.string(from: item.date)
            grouped[key, default: 0] += 1
        }

        return grouped
            .map { MonthlySummary(id: $0.key, monthLabel: $0.key, count: $0.value) }
            .sorted { $0.id < $1.id }
    }

    private var categorySessions: [CategorySummary] {
        var grouped: [ExerciseCategory: Int] = [:]
        for item in items {
            for category in item.categories {
                grouped[category, default: 0] += 1
            }
        }

        return grouped
            .map { CategorySummary(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HistoryCategoryFilter(selectedCategory: $selectedCategory)
                    .padding(.horizontal)

                if items.isEmpty {
                    HistoryEmptyState(message: "分析できる記録がありません。記録を追加してください。")
                        .frame(maxWidth: .infinity)
                } else {
                    if !monthlySessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("月別セッション数")
                                .font(.headline)
                            Chart {
                                ForEach(monthlySessions) { summary in
                                    BarMark(
                                        x: .value("月", summary.monthLabel),
                                        y: .value("回数", summary.count)
                                    )
                                }
                            }
                            .frame(height: 240)
                        }
                        .padding(.horizontal)
                    }

                    if !categorySessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("カテゴリ別内訳")
                                .font(.headline)
                            Chart {
                                ForEach(categorySessions) { summary in
                                    BarMark(
                                        x: .value("カテゴリ", summary.category.displayName),
                                        y: .value("回数", summary.count)
                                    )
                                }
                            }
                            .frame(height: 240)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical)
        }
    }

    private struct MonthlySummary: Identifiable {
        let id: String
        let monthLabel: String
        let count: Int
    }

    private struct CategorySummary: Identifiable {
        let id = UUID()
        let category: ExerciseCategory
        let count: Int
    }
}

private struct HistoryRow: View {
    let item: TrainingHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.dateLabel)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(item.title)
                .font(.headline)
            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryCategoryFilter: View {
    @Binding var selectedCategory: ExerciseCategory?

    var body: some View {
        Menu {
            Button(action: { selectedCategory = nil }) {
                Label("すべてのカテゴリ", systemImage: selectedCategory == nil ? "checkmark" : "circle")
            }
            Divider()
            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Label(category.displayName, systemImage: selectedCategory == category ? "checkmark" : "circle")
                }
            }
        } label: {
            Label(selectedCategory?.displayName ?? "カテゴリで絞り込み", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct HistoryEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 32)
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.previewContainer)
}
