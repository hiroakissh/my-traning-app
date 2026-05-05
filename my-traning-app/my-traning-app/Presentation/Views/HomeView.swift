import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var planner = AIWorkoutPlanner()
    @StateObject private var dashboardViewModel = HomeDashboardViewModel()
    private let lifecycle = WorkoutSessionLifecycleService()

    @State private var aiQuery: String = ""
    @State private var triggerSuggestion = false
    @State private var recommendationStatusMessage: String?

    @Query(sort: \ActivePlan.adoptedAt, order: .reverse) private var savedPlans: [ActivePlan]
    @Query(sort: \TrainingLog.date, order: .reverse) private var trainingLogs: [TrainingLog]
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \DailyRecommendation.generatedAt, order: .reverse) private var dailyRecommendations: [DailyRecommendation]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 2.5) {
                    header
                    todayRecommendationSection
                    dailyCheckInSection
                    todayMenuSection
                    weeklyProgressSection
                    metricsRow
                    recentLogSection
                    activePlanCard
                    aiAssistantCard
                }
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 2)
            }
            .hudScrollBackground()
            .applyIOSNavigationBarStyle()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await dashboardViewModel.refreshHealthData() }
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(dashboardViewModel.isLoadingHealth)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        Task { await dashboardViewModel.refreshHealthData() }
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(dashboardViewModel.isLoadingHealth)
                }
                #endif
            }
            .task { await dashboardViewModel.refreshHealthData() }
            .task(id: triggerSuggestion) {
                if triggerSuggestion {
                    let context = dashboardViewModel.makeAssistantContext(
                        query: aiQuery.isEmpty ? "今日できる軽めのメニューを提案して" : aiQuery,
                        logs: trainingLogs,
                        activePlan: savedPlans.first
                    )
                    await planner.suggestTodayWorkout(prompt: aiQuery.isEmpty ? "今日できる軽めのメニューを提案して" : aiQuery, context: context)
                    triggerSuggestion = false
                }
            }
            .refreshable {
                await dashboardViewModel.refreshHealthData()
            }
            .applyIOSNavigationBarChrome()
        }
        .hudBackground()
    }

    private var todayRecommendation: DailyRecommendation? {
        dailyRecommendations.first { Calendar.current.isDateInToday($0.date) }
    }

    private var todayCheckIn: DailyCheckIn? {
        checkIns.first { Calendar.current.isDateInToday($0.date) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                .font(AppTypography.label(14, weight: .semibold))
                .foregroundColor(AppColors.secondary)
            Text("ホーム")
                .font(AppTypography.title(30))
                .foregroundColor(AppColors.textPrimary)
            Text("今日の自分に合わせて、運動する・軽く動く・休むを決めます。")
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var todayRecommendationSection: some View {
        if let recommendation = todayRecommendation {
            HudSectionCard(title: nil, subtitle: nil, spacing: AppLayout.grid * 1.5) {
                HStack(spacing: AppLayout.grid) {
                    Image(systemName: recommendation.readinessLevel.systemImage)
                        .foregroundColor(AppColors.primary)
                    Text("今日の状態：\(recommendation.readinessLevel.displayName)")
                        .font(AppTypography.label(13, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text(recommendation.recommendationType.displayName)
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }

                Text("今日のおすすめ：\(recommendation.title)")
                    .font(AppTypography.title(24))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(recommendation.summary)
                    .font(AppTypography.body(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let notice = recommendation.generationNotice {
                    Label(notice, systemImage: "shield.lefthalf.filled")
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: AppLayout.grid * 0.7) {
                    Text("理由")
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.secondary)
                    ForEach(recommendation.reasons.prefix(3), id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.circle.fill")
                            .font(AppTypography.label())
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if recommendation.plannedExercises.isEmpty == false {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 0.7) {
                        Text("推奨メニュー")
                            .font(AppTypography.label(12, weight: .semibold))
                            .foregroundColor(AppColors.secondary)
                        ForEach(recommendation.plannedExercises.sorted { $0.order < $1.order }.prefix(3)) { exercise in
                            HStack {
                                Text(exercise.name)
                                    .font(AppTypography.body(14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if exercise.estimatedMinutes > 0 {
                                    Text("\(exercise.estimatedMinutes)分")
                                        .font(AppTypography.label(12))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                }

                VStack(spacing: AppLayout.grid) {
                    NavigationLink(destination: TodayRecommendationView(recommendation: recommendation)) {
                        Label("詳しく見る", systemImage: "doc.text.magnifyingglass")
                            .font(AppTypography.body(16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)

                    HStack(spacing: AppLayout.grid) {
                        if recommendation.recommendationType != .rest {
                            NavigationLink(destination: WorkoutSessionView(recommendation: recommendation)) {
                                Label("開始", systemImage: "play.fill")
                                    .font(AppTypography.body(15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(AppColors.secondary)
                            .simultaneousGesture(TapGesture().onEnded {
                                accept(.startedOriginalPlan, for: recommendation)
                            })
                        }

                        Button(action: { recordRest(for: recommendation) }) {
                            Label("休む", systemImage: "moon.zzz.fill")
                                .font(AppTypography.body(15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.textSecondary)
                    }

                    if let recommendationStatusMessage {
                        Text(recommendationStatusMessage)
                            .font(AppTypography.label())
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            HudSectionCard(title: nil, subtitle: nil, spacing: AppLayout.grid * 1.4) {
                Text("今日の処方箋")
                    .font(AppTypography.title(24))
                    .foregroundColor(AppColors.textPrimary)
                Text("まず今日の状態をチェックインすると、運動する・軽く動く・休むの提案を作ります。")
                    .font(AppTypography.body(15))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink(destination: DailyCheckInView()) {
                    Label("チェックインする", systemImage: "checklist")
                        .font(AppTypography.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
            }
        }
    }

    private var dailyCheckInSection: some View {
        HudSectionCard(title: "Daily Check-In", subtitle: nil, spacing: AppLayout.grid) {
            if let checkIn = todayCheckIn {
                HStack(spacing: AppLayout.grid) {
                    checkInMetric(title: "睡眠", value: checkIn.sleepQuality.displayName)
                    checkInMetric(title: "疲労", value: checkIn.fatigueLevel.displayName)
                    checkInMetric(title: "時間", value: "\(checkIn.availableMinutes)分")
                }
                NavigationLink(destination: DailyCheckInView()) {
                    Label("今日の状態を更新", systemImage: "arrow.clockwise")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.secondary)
            } else {
                Text("未チェックインです。数タップで今日の提案を作れます。")
                    .font(AppTypography.label())
                    .foregroundColor(AppColors.textSecondary)
                NavigationLink(destination: DailyCheckInView()) {
                    Label("チェックインする", systemImage: "checklist")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.primary)
            }
        }
    }

    @ViewBuilder
    private var todayMenuSection: some View {
        if let recommendation = todayRecommendation, recommendation.plannedExercises.isEmpty == false {
            HudSectionCard(title: "今日やること", subtitle: nil, spacing: AppLayout.grid) {
                ForEach(recommendation.plannedExercises.sorted { $0.order < $1.order }) { exercise in
                    HStack(alignment: .top, spacing: AppLayout.grid) {
                        Image(systemName: exercise.category == .cardio ? "figure.walk" : exercise.category == .mobility ? "figure.cooldown" : "dumbbell")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
                            Text(exercise.name)
                                .font(AppTypography.body(14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text(exercise.detail)
                                .font(AppTypography.label(12))
                                .foregroundColor(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var weeklyProgressSection: some View {
        let completedThisWeek = trainingLogs.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count
        let hasRecovery = dailyRecommendations.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
            && ($0.acceptedAction == .changedToRest || $0.recommendationType == .rest || $0.recommendationType == .recovery)
        }.count
        let plannedDays = max(completedThisWeek + hasRecovery, 4)
        let adherence = min(Double(completedThisWeek + hasRecovery) / Double(plannedDays), 1)

        return HudSectionCard(title: "今週の進捗", subtitle: "休養も計画遵守として扱います。", spacing: AppLayout.grid * 1.2, useSecondarySurface: true) {
            ProgressView(value: adherence) {
                Text("計画遵守率 \(Int(adherence * 100))%")
                    .font(AppTypography.body(14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            .tint(AppColors.primary)

            HStack(spacing: AppLayout.grid) {
                weeklyMetric(title: "実行", value: "\(completedThisWeek)回")
                weeklyMetric(title: "休養", value: "\(hasRecovery)日")
                weeklyMetric(title: "予定", value: "\(plannedDays)日")
            }
        }
    }

    private var goalCard: some View {
        let snapshot = dashboardViewModel.dashboard(logs: trainingLogs)
        return HudSectionCard(title: nil, subtitle: nil, spacing: AppLayout.grid * 2.5) {
            VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                Text("DAILY GOAL")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
                CircularGoalView(
                    progress: snapshot.progressRate,
                    burned: snapshot.burnedKcal,
                    goal: snapshot.dailyGoalKcal
                )
                if dashboardViewModel.isLoadingHealth {
                    ProgressView()
                        .tint(AppColors.primary)
                } else if let message = dashboardViewModel.healthErrorMessage {
                    Text(message)
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var metricsRow: some View {
        let snapshot = dashboardViewModel.dashboard(logs: trainingLogs)
        return HStack(spacing: AppLayout.grid * 1.5) {
            MetricCard(
                icon: "figure.run.circle.fill",
                title: "Morning Run",
                value: snapshot.distanceKm.map { String(format: "%.1f km", $0) } ?? "-- km"
            )
            MetricCard(
                icon: "heart.circle.fill",
                title: "Avg Heart Rate",
                value: snapshot.averageHeartRate.map { "\(Int($0)) bpm" } ?? "-- bpm"
            )
        }
    }

    @ViewBuilder
    private var recentLogSection: some View {
        let snapshot = dashboardViewModel.dashboard(logs: trainingLogs)
        HudSectionCard(title: "最近の記録", subtitle: nil, spacing: AppLayout.grid, useSecondarySurface: true) {
            if let title = snapshot.latestWorkoutTitle {
                Text(title)
                    .font(AppTypography.body(16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                if let subtitle = snapshot.latestWorkoutSubtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textSecondary)
                }
                if let minutes = snapshot.latestDurationMinutes {
                    Text("\(minutes)分")
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.secondary)
                }
            } else {
                Text("まだ記録はありません。今日の提案から始めると、次回以降の判断に反映されます。")
                    .font(AppTypography.label())
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private var activePlanCard: some View {
        HudSectionCard(title: "アクティブプラン", subtitle: nil, spacing: AppLayout.grid * 1.5, useSecondarySurface: true) {
            if let activePlan = savedPlans.first {
                VStack(alignment: .leading, spacing: AppLayout.grid) {
                    Text(activePlan.title)
                        .font(AppTypography.body(17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(activePlan.summary)
                        .font(AppTypography.label(13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                    Text(activePlan.detail)
                        .font(AppTypography.label(12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(3)
                }
            } else {
                Text("まだプランが設定されていません。プランタブからAIに再提案を依頼してください。")
                    .font(AppTypography.label())
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var aiAssistantCard: some View {
        HudSectionCard(title: "AI相談", subtitle: "迷ったときだけ補助的に使います。今日の提案はチェックインから作ります。", spacing: AppLayout.grid * 1.2) {
            if let errorMessage = planner.errorMessage {
                HStack(alignment: .top, spacing: AppLayout.grid) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            if !planner.todaySuggestion.isEmpty {
                HStack(alignment: .top, spacing: AppLayout.grid) {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.primary)
                    Text(planner.todaySuggestion)
                        .font(AppTypography.body(15))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(AppColors.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
            }

            TextField("今日は忙しいけど何ができる？", text: $aiQuery)
                .hudFieldStyle()
                .disabled(planner.isLoading)

            Button(action: { triggerSuggestion = true }) {
                if planner.isLoading {
                    ProgressView()
                        .tint(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("質問する")
                        .font(AppTypography.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(planner.isLoading)
        }
    }

    private func checkInMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
            Text(title)
                .font(AppTypography.label(12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.body(15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.grid)
        .background(AppColors.surface2.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }

    private func weeklyMetric(title: String, value: String) -> some View {
        VStack(spacing: AppLayout.grid * 0.3) {
            Text(value)
                .font(AppTypography.body(17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(title)
                .font(AppTypography.label(12))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppLayout.grid)
        .background(AppColors.surface.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }

    private func accept(_ action: AcceptedAction, for recommendation: DailyRecommendation) {
        recommendation.acceptedAction = action
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save accepted action: \(error.localizedDescription)")
        }
    }

    private func recordRest(for recommendation: DailyRecommendation) {
        recommendation.acceptedAction = .changedToRest
        let log = lifecycle.makeRestedLog(
            from: recommendation,
            note: "休養も計画の一部として記録",
            changedToRest: recommendation.recommendationType != .rest
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            recommendationStatusMessage = "休養として記録しました。"
        } catch {
            recommendationStatusMessage = "保存に失敗しました。"
        }
    }
}

private struct CircularGoalView: View {
    var progress: Double
    var burned: Double
    var goal: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 16)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [AppColors.secondary, AppColors.primary]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 8) {
                Text("\(Int(progress * 100)) %")
                    .font(AppTypography.hudNumber(42, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(String(format: "%.0f / %.0f kcal", burned, goal))
                    .font(AppTypography.body(15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppLayout.grid * 2)
                    .padding(.vertical, AppLayout.grid)
                    .background(AppColors.surface2.opacity(0.9))
                    .clipShape(Capsule())
            }
        }
        .frame(height: 220)
    }
}

private struct MetricCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid) {
            HStack(spacing: AppLayout.grid) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
                Text(title)
                    .font(AppTypography.label(13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(value)
                .font(AppTypography.body(20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCardStyle(secondary: true)
    }
}

#Preview {
    HomeView()
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
}

private extension View {
    @ViewBuilder
    func applyIOSNavigationBarStyle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func applyIOSNavigationBarChrome() -> some View {
        #if os(iOS)
        self
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }
}
