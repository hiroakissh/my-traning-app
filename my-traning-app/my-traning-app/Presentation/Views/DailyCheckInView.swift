import SwiftUI
import SwiftData

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var planner = AIWorkoutPlanner()

    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \DailyRecommendation.generatedAt, order: .reverse) private var recommendations: [DailyRecommendation]
    @Query(sort: \TrainingLog.date, order: .reverse) private var trainingLogs: [TrainingLog]
    @Query(sort: \ActivePlan.adoptedAt, order: .reverse) private var savedPlans: [ActivePlan]
    @Query(sort: \UserGoal.priority, order: .reverse) private var goals: [UserGoal]

    @State private var sleepQuality: SleepQuality = .normal
    @State private var fatigueLevel: FatigueLevel = .normal
    @State private var moodLevel: MoodLevel = .normal
    @State private var sorenessLevel: SorenessLevel = .none
    @State private var availableMinutes: Int = 30
    @State private var motivationLevel: MotivationLevel = .normal
    @State private var note: String = ""
    @State private var isGenerating = false
    @State private var persistenceError: String?

    private let minuteOptions = [10, 30, 60]
    private let generator = DailyRecommendationGenerator()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                header
                checkInForm
                submitButton
                if let errorMessage = planner.errorMessage {
                    statusBanner(errorMessage)
                }
            }
            .padding(.horizontal, AppLayout.grid * 2)
            .padding(.vertical, AppLayout.grid * 2.5)
        }
        .hudScrollBackground()
        .navigationTitle("")
        .applyIOSNavigationBarHidden(true)
        .alert("チェックインを保存できませんでした", isPresented: Binding(get: { persistenceError != nil }, set: { _ in persistenceError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            if let persistenceError {
                Text(persistenceError)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.8) {
            Text("今日の状態を教えてください")
                .font(AppTypography.title(26))
                .foregroundColor(AppColors.textPrimary)
            Text("数タップで、今日やることを決めます。")
                .font(AppTypography.label())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var checkInForm: some View {
        HudSectionCard(title: nil, subtitle: nil, spacing: AppLayout.grid * 1.8) {
            choiceRow(
                title: "睡眠",
                items: SleepQuality.allCases.map { ChoiceItem(id: $0.rawValue, title: $0.displayName, systemImage: sleepIcon($0)) },
                selection: sleepQuality.rawValue
            ) { sleepQuality = SleepQuality(rawValue: $0) ?? .normal }

            choiceRow(
                title: "疲労",
                items: FatigueLevel.allCases.map { ChoiceItem(id: $0.rawValue, title: $0.displayName, systemImage: fatigueIcon($0)) },
                selection: fatigueLevel.rawValue
            ) { fatigueLevel = FatigueLevel(rawValue: $0) ?? .normal }

            choiceRow(
                title: "気分",
                items: MoodLevel.allCases.map { ChoiceItem(id: $0.rawValue, title: $0.displayName, systemImage: moodIcon($0)) },
                selection: moodLevel.rawValue
            ) { moodLevel = MoodLevel(rawValue: $0) ?? .normal }

            choiceRow(
                title: "筋肉痛",
                items: SorenessLevel.allCases.map { ChoiceItem(id: $0.rawValue, title: $0.displayName, systemImage: sorenessIcon($0)) },
                selection: sorenessLevel.rawValue
            ) { sorenessLevel = SorenessLevel(rawValue: $0) ?? .none }

            choiceRow(
                title: "使える時間",
                items: minuteOptions.map { ChoiceItem(id: "\($0)", title: $0 >= 60 ? "60分以上" : "\($0)分", systemImage: "clock") },
                selection: "\(availableMinutes)"
            ) { availableMinutes = Int($0) ?? 30 }

            choiceRow(
                title: "やる気",
                items: MotivationLevel.allCases.map { ChoiceItem(id: $0.rawValue, title: $0.displayName, systemImage: motivationIcon($0)) },
                selection: motivationLevel.rawValue
            ) { motivationLevel = MotivationLevel(rawValue: $0) ?? .normal }

            TextField("メモ（任意）", text: $note, axis: .vertical)
                .lineLimit(1...3)
                .hudFieldStyle()
        }
    }

    private var submitButton: some View {
        Button(action: {
            Task { await saveCheckInAndGenerateRecommendation() }
        }) {
            if isGenerating || planner.isLoading {
                ProgressView()
                    .tint(AppColors.background)
                    .frame(maxWidth: .infinity)
            } else {
                Label("今日の提案を作る", systemImage: "sparkles")
                    .font(AppTypography.body(17, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, AppLayout.grid * 1.2)
        .buttonStyle(.borderedProminent)
        .tint(AppColors.primary)
        .disabled(isGenerating || planner.isLoading)
    }

    private func choiceRow(
        title: String,
        items: [ChoiceItem],
        selection: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid) {
            Text(title)
                .font(AppTypography.label(13, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: AppLayout.grid) {
                ForEach(items) { item in
                    Button(action: { onSelect(item.id) }) {
                        VStack(spacing: AppLayout.grid * 0.5) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                            Text(item.title)
                                .font(AppTypography.label(12, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(selection == item.id ? AppColors.primary : AppColors.surface2.opacity(0.9))
                        .foregroundColor(selection == item.id ? AppColors.background : AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous)
                                .stroke(AppColors.strokeGlow, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func saveCheckInAndGenerateRecommendation() async {
        isGenerating = true
        defer { isGenerating = false }

        let today = Calendar.current.startOfDay(for: Date())
        let checkIn = DailyCheckIn(
            date: today,
            sleepQuality: sleepQuality,
            fatigueLevel: fatigueLevel,
            moodLevel: moodLevel,
            sorenessLevel: sorenessLevel,
            availableMinutes: availableMinutes,
            motivationLevel: motivationLevel,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        )

        deleteTodayModels()
        modelContext.insert(checkIn)

        await planner.generateDailyRecommendation(
            checkIn: checkIn,
            goal: goals.sorted { $0.priority > $1.priority }.first,
            recentLogs: trainingLogs,
            activePlan: savedPlans.first
        )

        let recommendation = if let output = planner.dailyRecommendationOutput {
            output.makeModel(date: today)
        } else {
            generator.generate(
                checkIn: checkIn,
                goal: goals.sorted { $0.priority > $1.priority }.first,
                recentLogs: trainingLogs,
                activePlan: savedPlans.first
            )
        }
        modelContext.insert(recommendation)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func deleteTodayModels() {
        let calendar = Calendar.current
        for checkIn in checkIns where calendar.isDateInToday(checkIn.date) {
            modelContext.delete(checkIn)
        }
        for recommendation in recommendations where calendar.isDateInToday(recommendation.date) {
            modelContext.delete(recommendation)
        }
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: AppLayout.grid) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppColors.secondary)
            Text("AI提案は利用できなかったため、チェックイン内容からルールベースで提案します。\(message)")
                .font(AppTypography.label())
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(AppLayout.grid * 1.25)
        .background(AppColors.surface2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }

    private func sleepIcon(_ value: SleepQuality) -> String {
        switch value {
        case .poor: return "moon.zzz"
        case .normal: return "moon"
        case .good: return "moon.stars.fill"
        }
    }

    private func fatigueIcon(_ value: FatigueLevel) -> String {
        switch value {
        case .high: return "battery.25"
        case .normal: return "battery.50"
        case .low: return "battery.100"
        }
    }

    private func moodIcon(_ value: MoodLevel) -> String {
        switch value {
        case .low: return "cloud"
        case .normal: return "circle"
        case .high: return "sun.max.fill"
        }
    }

    private func sorenessIcon(_ value: SorenessLevel) -> String {
        switch value {
        case .none: return "checkmark.circle"
        case .mild: return "waveform.path.ecg"
        case .strong: return "exclamationmark.triangle"
        }
    }

    private func motivationIcon(_ value: MotivationLevel) -> String {
        switch value {
        case .low: return "minus.circle.fill"
        case .normal: return "figure.walk"
        case .high: return "flame.fill"
        }
    }
}

private struct ChoiceItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
}

#Preview {
    NavigationStack {
        DailyCheckInView()
    }
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
            UserGoal.self,
            WeeklyReview.self
        ] as [any PersistentModel.Type],
        inMemory: true
    )
}

private extension View {
    @ViewBuilder
    func applyIOSNavigationBarHidden(_ hidden: Bool) -> some View {
        #if os(iOS)
        self.navigationBarHidden(hidden)
        #else
        self
        #endif
    }
}
