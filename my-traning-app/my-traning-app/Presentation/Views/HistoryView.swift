import SwiftUI
import SwiftData

private enum HistoryDisplayMode: Int, CaseIterable {
    case calendar
    case list

    var title: String {
        switch self {
        case .calendar: return "カレンダー"
        case .list: return "リスト"
        }
    }
}

struct HistoryView: View {
    @Environment(\.calendar) private var calendar
    @Query(sort: \TrainingLog.date, order: .reverse) private var logs: [TrainingLog]

    @State private var selectedMode: HistoryDisplayMode = .calendar
    @State private var searchText: String = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedDate: Date = Date()

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
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                    header
                    modeSwitcher
                    searchBar
                    categoryChips

                    switch selectedMode {
                    case .calendar:
                        calendarSection
                    case .list:
                        listSection
                    }
                }
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 2.5)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .hudBackground()
            .onAppear(perform: initializeSelectedDate)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text("履歴")
                .font(AppTypography.title(26))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Mode switcher
    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(HistoryDisplayMode.allCases, id: \.self) { mode in
                Button(action: { selectedMode = mode }) {
                    HStack(spacing: AppLayout.grid) {
                        Image(systemName: mode == .calendar ? "calendar" : "list.bullet")
                        Text(mode.title)
                            .font(AppTypography.body(15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppLayout.grid * 1.25)
                    .background(mode == selectedMode ? AppColors.primary : AppColors.surface2)
                    .foregroundColor(mode == selectedMode ? AppColors.background : AppColors.textSecondary)
                }
            }
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    // MARK: - Search
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            TextField("検索...", text: $searchText)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, AppLayout.grid * 1.2)
        .padding(.horizontal, AppLayout.grid * 1.6)
        .background(AppColors.surface2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    // MARK: - Category Chips
    private var categoryChips: some View {
        HStack(spacing: AppLayout.grid) {
            categoryChip(title: "すべて", isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }
            categoryChip(title: ExerciseCategory.strength.displayName, isSelected: selectedCategory == .strength) {
                selectedCategory = .strength
            }
            categoryChip(title: ExerciseCategory.cardio.displayName, isSelected: selectedCategory == .cardio) {
                selectedCategory = .cardio
            }
        }
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.label(13, weight: .semibold))
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 0.8)
                .background(isSelected ? AppColors.primary : AppColors.surface2)
                .foregroundColor(isSelected ? AppColors.background : AppColors.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(AppColors.strokeGlow, lineWidth: 1)
                )
        }
    }

    // MARK: - Calendar
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            monthHeader
            calendarGrid
            daySummary
        }
    }

    private var monthHeader: some View {
        HStack {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            Text(selectedDate, format: .dateTime.year().month())
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, AppLayout.grid * 1.5)
    }

    private var calendarGrid: some View {
        let days = MonthBuilder.days(in: selectedDate, calendar: calendar)
        return VStack(spacing: AppLayout.grid) {
            HStack {
                ForEach(0..<7) { index in
                    Text(calendar.shortWeekdaySymbols[index])
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(days, id: \.self) { week in
                HStack {
                    ForEach(week, id: \.self) { date in
                        calendarDayCell(date: date)
                    }
                }
            }
        }
        .padding(AppLayout.grid * 1.5)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    private func calendarDayCell(date: Date?) -> some View {
        let isSelected = date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false
        let hasLog = date.map { dayHasLog($0) } ?? false
        let text = date.map { String(calendar.component(.day, from: $0)) } ?? ""

        return Button(action: {
            if let date { selectedDate = date }
        }) {
            VStack(spacing: AppLayout.grid * 0.6) {
                Text(text)
                    .font(AppTypography.body(15, weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                if hasLog {
                    Circle()
                        .fill(isSelected ? AppColors.background : AppColors.primary)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppLayout.grid * 0.8)
            .background(
                Circle()
                    .fill(isSelected ? AppColors.primary : Color.clear)
                    .frame(width: 44, height: 44)
            )
        }
        .disabled(date == nil)
    }

    // MARK: - Day summary
    private var daySummary: some View {
        let summary = daySummary(for: selectedDate)
        return VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            HStack {
                Text(selectedDate, format: .dateTime.year().month().day().weekday())
                    .font(AppTypography.body(17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if summary.totalDurationSec > 0 {
                    Text("完了")
                        .font(AppTypography.label(12, weight: .semibold))
                        .padding(.horizontal, AppLayout.grid * 1.5)
                        .padding(.vertical, AppLayout.grid * 0.5)
                        .background(AppColors.surface2)
                        .foregroundColor(AppColors.textPrimary)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: AppLayout.grid * 1.25) {
                summaryCard(
                    icon: "timer",
                    title: "時間",
                    value: summary.durationText
                )
                summaryCard(
                    icon: "flame.fill",
                    title: "ボリューム",
                    value: summary.volumeText
                )
                summaryCard(
                    icon: "dumbbell.fill",
                    title: "目的",
                    value: summary.purposeText
                )
            }
        }
    }

    private func summaryCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.6) {
            HStack(spacing: AppLayout.grid * 0.6) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
                Text(title)
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(value)
                .font(AppTypography.body(16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.grid * 1.25)
        .background(AppColors.surface2.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    // MARK: - List
    private var listSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            if filteredItems.isEmpty {
                HistoryEmptyState(message: "表示できる記録がありません。検索やカテゴリを調整してください。")
            } else {
                ForEach(groupedByDay(filteredItems), id: \.date) { group in
                    VStack(alignment: .leading, spacing: AppLayout.grid) {
                        Text(group.label)
                            .font(AppTypography.body(15, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.leading, AppLayout.grid * 0.5)

                        VStack(spacing: AppLayout.grid * 1.2) {
                            ForEach(group.items) { item in
                                NavigationLink(destination: TrainingLogDetailView(log: item.log, item: item)) {
                                    listRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func listRow(item: TrainingHistoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppLayout.grid * 0.8) {
                HStack(spacing: AppLayout.grid * 0.8) {
                    icon(for: item)
                        .foregroundColor(AppColors.primary)
                    Text(item.title)
                        .font(AppTypography.body(16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                HStack(spacing: AppLayout.grid) {
                    if let start = item.log.startTime {
                        Text(DateFormatter.hudDay.string(from: start))
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let cardio = item.log.cardio {
                        Text(String(format: "%.1f km", cardio.distanceInKilometers))
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Text("\(Int(item.log.sessionDurationSec / 60)) min")
                        .font(AppTypography.label(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
            Text("\(Int(item.log.sessionDurationSec / 60))")
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, AppLayout.grid)
                .overlay(
                    Text("min")
                        .font(AppTypography.label(11))
                        .foregroundColor(AppColors.textSecondary)
                        .offset(y: 12),
                    alignment: .bottom
                )
        }
        .padding(AppLayout.grid * 1.5)
        .background(AppColors.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    // MARK: - Helpers
    private func initializeSelectedDate() {
        if let latestDate = logs.first?.date {
            selectedDate = latestDate
        }
    }

    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func dayHasLog(_ date: Date) -> Bool {
        historyItems.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func daySummary(for date: Date) -> DaySummary {
        let daily = TrainingLogAnalytics.dailySummaries(from: logs, calendar: calendar)
        guard let summary = daily.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) else {
            return .init(totalDurationSec: 0, totalVolumeKg: 0, purposes: [])
        }
        return .init(
            totalDurationSec: summary.totalDurationSec,
            totalVolumeKg: summary.totalVolumeKg,
            purposes: Array(summary.purposeCounts.keys)
        )
    }

    private func groupedByDay(_ items: [TrainingHistoryItem]) -> [DayGroup] {
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.date)
        }
        return grouped.map { date, items in
            DayGroup(date: date, label: DateFormatter.hudDay.string(from: date), items: items.sorted { $0.date > $1.date })
        }
        .sorted { $0.date > $1.date }
    }

    private func icon(for item: TrainingHistoryItem) -> Image {
        if item.categories.contains(.cardio) {
            return Image(systemName: "figure.run.circle.fill")
        }
        return Image(systemName: "dumbbell.fill")
    }
}

// MARK: - Models
private struct DaySummary {
    let totalDurationSec: Int
    let totalVolumeKg: Double
    let purposes: [TrainingPurpose]

    var durationText: String {
        let minutes = totalDurationSec / 60
        if minutes == 0 { return "--" }
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)時間\(m)分" : "\(m)分"
    }

    var volumeText: String {
        if totalVolumeKg <= 0 { return "--" }
        return "\(Int(totalVolumeKg.rounded())) kg"
    }

    var purposeText: String {
        if purposes.isEmpty { return "未設定" }
        return purposes.map { $0.displayName }.joined(separator: "・")
    }
}

private struct DayGroup {
    let date: Date
    let label: String
    let items: [TrainingHistoryItem]
}

private struct MonthBuilder {
    static func days(in date: Date, calendar: Calendar) -> [[Date?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let monthStart = monthInterval.start
        // Use ClosedRange<Int> explicitly to avoid Range/ClosedRange mismatch
        let range: ClosedRange<Int>
        if let r = calendar.range(of: .day, in: .month, for: monthStart) {
            range = r.lowerBound...r.upperBound - 1
        } else {
            range = 1...30
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart) // 1 = Sunday
        var days: [Date?] = Array(repeating: nil, count: max(0, firstWeekday - 1))

        for day in range {
            if let dayDate = calendar.date(byAdding: DateComponents(day: day - 1), to: monthStart) {
                days.append(dayDate)
            }
        }

        // Pad to full weeks
        while days.count % 7 != 0 {
            days.append(nil)
        }

        let rows: [[Date?]] = stride(from: 0, to: days.count, by: 7).map { index in
            Array(days[index..<min(index + 7, days.count)])
        }

        return rows
    }
}

private struct HistoryEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: AppLayout.grid) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(AppColors.textSecondary)
            Text(message)
                .font(AppTypography.body(14))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, AppLayout.grid * 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.previewContainer)
}
