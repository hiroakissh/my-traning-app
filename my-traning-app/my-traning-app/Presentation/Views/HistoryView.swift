import SwiftUI

private enum HistoryMode: String, CaseIterable, Identifiable {
    case calendar = "カレンダー"
    case list = "リスト"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .list: return "list.bullet"
        }
    }
}

private struct HistoryEvent: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let startTime: String
    let durationMinutes: Int
    let distanceKm: Double?
    let calories: Int?
    let intensity: String?
    let icon: String
    let color: Color
}

private let sampleEvents: [HistoryEvent] = {
    let calendar = Calendar.current
    let now = Date()
    func makeDate(_ day: Int) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: day)) ?? now
    }
    return [
        HistoryEvent(date: makeDate(24), title: "朝のランニング", startTime: "06:30", durationMinutes: 32, distanceKm: 5.2, calories: 330, intensity: nil, icon: "figure.run", color: AppColors.primary),
        HistoryEvent(date: makeDate(23), title: "リカバリースイム", startTime: "19:15", durationMinutes: 20, distanceKm: 1.0, calories: 180, intensity: nil, icon: "figure.pool.swim", color: Color.blue),
        HistoryEvent(date: makeDate(23), title: "上半身パワー", startTime: "18:00", durationMinutes: 45, distanceKm: nil, calories: 420, intensity: "高強度", icon: "dumbbell.fill", color: Color.purple),
        HistoryEvent(date: makeDate(20), title: "ロングライド", startTime: "10:00", durationMinutes: 90, distanceKm: 25.0, calories: 650, intensity: nil, icon: "bicycle", color: Color.orange)
    ]
}()

struct HistoryView: View {
    @State private var selectedMode: HistoryMode = .calendar
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()

    private var eventsByDay: [Int: [HistoryEvent]] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: currentMonth)
        return Dictionary(grouping: sampleEvents.filter {
            let dc = calendar.dateComponents([.year, .month, .day], from: $0.date)
            return dc.year == comps.year && dc.month == comps.month
        }) { calendar.component(.day, from: $0.date) }
    }

    private var selectedDayEvents: [HistoryEvent] {
        let day = Calendar.current.component(.day, from: selectedDate)
        return eventsByDay[day] ?? []
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            background
            VStack(spacing: AppLayout.grid * 2) {
                header
                modeSwitcher

                if selectedMode == .calendar {
                    calendarContent
                } else {
                    listContent
                }
                Spacer(minLength: AppLayout.grid * 4)
            }
            .padding(.horizontal, AppLayout.grid * 2.5)
            .padding(.top, AppLayout.grid * 3)
        }
        .navigationBarHidden(true)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                AppColors.background,
                AppColors.surface.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppLayout.grid * 1.25)
                    .background(Circle().stroke(AppColors.divider, lineWidth: 1))
            }
            Spacer()
            Text("履歴")
                .font(AppTypography.title(20))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(AppColors.textSecondary)
                    .padding(AppLayout.grid * 1.25)
                    .background(Circle().stroke(AppColors.divider, lineWidth: 1))
            }
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(HistoryMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    HStack(spacing: AppLayout.grid * 0.75) {
                        Image(systemName: mode.icon)
                        Text(mode.rawValue)
                            .font(AppTypography.body(15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppLayout.grid * 1.2)
                    .foregroundColor(selectedMode == mode ? AppColors.background : AppColors.textSecondary)
                    .background(
                        Capsule()
                            .fill(selectedMode == mode ? AppColors.primary : AppColors.surface.opacity(0.85))
                    )
                }
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(AppColors.surface.opacity(0.75))
                .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
        )
    }

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
            monthHeader
            CalendarGrid(currentMonth: $currentMonth, selectedDate: $selectedDate, eventsByDay: eventsByDay)
            summarySection
            filterChips
        }
    }

    private var monthHeader: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return HStack {
            Button(action: { shiftMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            Text(formatter.string(from: currentMonth))
                .font(AppTypography.title(20))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: { shiftMonth(1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid) {
            HStack(spacing: AppLayout.grid) {
                Text(dateSummaryTitle)
                    .font(AppTypography.title(18))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("完了")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, AppLayout.grid * 1.25)
                    .padding(.vertical, AppLayout.grid * 0.75)
                    .background(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).stroke(AppColors.primary, lineWidth: 1))
            }

            HStack(spacing: AppLayout.grid * 1.25) {
                SummaryPill(icon: "timer", color: AppColors.primary, title: "時間", value: "1時間20分")
                SummaryPill(icon: "flame.fill", color: Color.orange, title: "消費kcal", value: "650")
                SummaryPill(icon: "figure.strengthtraining.traditional", color: Color.blue.opacity(0.8), title: "重点", value: "筋力強化")
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.grid * 1.25) {
                SearchBar()
                FilterChip(title: "すべて", isActive: true)
                FilterChip(title: "筋トレ", isActive: false)
            }
        }
    }

    private var listContent: some View {
        VStack(spacing: AppLayout.grid * 2) {
            SearchBar()
            FilterChipRow()

            ForEach(groupedEvents(), id: \.label) { group in
                VStack(alignment: .leading, spacing: AppLayout.grid * 1.1) {
                    HStack(spacing: AppLayout.grid * 0.75) {
                        Rectangle()
                            .fill(group.accent)
                            .frame(width: 3, height: 18)
                            .cornerRadius(2)
                        Text(group.label)
                            .font(AppTypography.body(15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        if let subtitle = group.subtitle {
                            Text(subtitle)
                                .font(AppTypography.label(12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    VStack(spacing: AppLayout.grid * 1.25) {
                        ForEach(group.items) { item in
                            HistoryCard(event: item)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func shiftMonth(_ delta: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = newDate
            selectedDate = newDate
        }
    }

    private var dateSummaryTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return "\(formatter.string(from: selectedDate)) のまとめ"
    }

    private struct GroupedEvents {
        let label: String
        let subtitle: String?
        let accent: Color
        let items: [HistoryEvent]
    }

    private func groupedEvents() -> [GroupedEvents] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")

        let groups = Dictionary(grouping: sampleEvents) { event -> String in
            let start = calendar.startOfDay(for: event.date)
            let diff = calendar.dateComponents([.day], from: start, to: today).day ?? 0
            if diff == 0 { return "今日" }
            if diff == 1 { return "昨日" }
            return formatter.string(from: event.date)
        }

        return groups.map { key, items in
            let sample = items.first!
            let accent: Color
            switch key {
            case "今日": accent = AppColors.primary
            case "昨日": accent = Color.blue.opacity(0.8)
            default: accent = Color.orange.opacity(0.9)
            }
            let subtitle: String? = (key == "今日" || key == "昨日") ? dateLabel(sample.date) : nil
            return GroupedEvents(label: key, subtitle: subtitle, accent: accent, items: items.sorted { $0.startTime < $1.startTime })
        }
        .sorted { lhs, rhs in
            let order: [String: Int] = ["今日": 0, "昨日": 1]
            let l = order[lhs.label] ?? 2
            let r = order[rhs.label] ?? 2
            if l != r { return l < r }
            return lhs.label > rhs.label
        }
    }

    private func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Components

private struct CalendarGrid: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let eventsByDay: [Int: [HistoryEvent]]

    var body: some View {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<31
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        VStack(spacing: AppLayout.grid * 1.25) {
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    Text(day)
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let blanks = (firstWeekday + 6) % 7
            let total = blanks + range.count
            let rows = Int(ceil(Double(total) / 7.0))
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < blanks || index - blanks >= range.count {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        } else {
                            let day = index - blanks + 1
                            let isSelected = calendar.component(.day, from: selectedDate) == day &&
                                calendar.isDate(selectedDate, equalTo: currentMonth, toGranularity: .month)
                            let hasEvent = eventsByDay[day] != nil
                            Button {
                                if let newDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: currentMonth), month: calendar.component(.month, from: currentMonth), day: day)) {
                                    selectedDate = newDate
                                }
                            } label: {
                                VStack(spacing: AppLayout.grid * 0.5) {
                                    Text("\(day)")
                                        .font(AppTypography.body(15, weight: .semibold))
                                        .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                    Circle()
                                        .fill(hasEvent ? AppColors.primary : .clear)
                                        .frame(width: 6, height: 6)
                                }
                                .padding(.vertical, AppLayout.grid * 1.1)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Circle()
                                        .fill(isSelected ? AppColors.primary.opacity(0.9) : Color.clear)
                                        .shadow(color: isSelected ? AppColors.primary.opacity(0.25) : .clear, radius: 8, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.vertical, AppLayout.grid * 1.25)
        .padding(.horizontal, AppLayout.grid)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
        )
    }
}

private struct SummaryPill: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: AppLayout.grid * 0.6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(AppTypography.label(12))
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.body(16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppLayout.grid * 1.5)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
        )
    }
}

private struct SearchBar: View {
    var body: some View {
        HStack(spacing: AppLayout.grid) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            Text("検索…")
                .font(AppTypography.body(14))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, AppLayout.grid * 1.5)
        .padding(.vertical, AppLayout.grid * 1.1)
        .background(
            Capsule()
                .fill(AppColors.surface.opacity(0.85))
                .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
        )
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        Text(title)
            .font(AppTypography.body(14, weight: .semibold))
            .foregroundColor(isActive ? AppColors.background : AppColors.textSecondary)
            .padding(.horizontal, AppLayout.grid * 1.6)
            .padding(.vertical, AppLayout.grid * 1.0)
            .background(
                Capsule()
                    .fill(isActive ? AppColors.primary : AppColors.surface.opacity(0.85))
                    .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
            )
    }
}

private struct FilterChipRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.grid * 1.25) {
                FilterChip(title: "すべて", isActive: true)
                FilterChip(title: "筋トレ", isActive: false)
                FilterChip(title: "有酸素", isActive: false)
            }
        }
    }
}

private struct HistoryCard: View {
    let event: HistoryEvent

    var body: some View {
        HStack(spacing: AppLayout.grid * 1.25) {
            ZStack {
                Circle()
                    .fill(event.color.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: event.icon)
                    .foregroundColor(event.color)
                    .font(.system(size: 18, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: AppLayout.grid * 0.6) {
                Text(event.title)
                    .font(AppTypography.body(16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                HStack(spacing: AppLayout.grid) {
                    Text(event.startTime)
                        .font(AppTypography.label(12))
                        .foregroundColor(AppColors.textSecondary)
                    if let distance = event.distanceKm {
                        Label("\(distance, specifier: "%.1f") km", systemImage: "mappin.and.ellipse")
                            .labelStyle(.titleAndIcon)
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let calories = event.calories {
                        Text("\(calories) kcal")
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    if let intensity = event.intensity {
                        Text(intensity)
                            .font(AppTypography.label(12))
                            .foregroundColor(event.color.opacity(0.9))
                    }
                }
            }
            Spacer()
            VStack {
                Text("\(event.durationMinutes)")
                    .font(AppTypography.title(22))
                    .foregroundColor(AppColors.textPrimary)
                Text("min")
                    .font(AppTypography.label(12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppLayout.grid * 1.75)
        .padding(.vertical, AppLayout.grid * 1.3)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.14), radius: 12, x: 0, y: 8)
        )
    }
}

#Preview {
    HistoryView()
}
