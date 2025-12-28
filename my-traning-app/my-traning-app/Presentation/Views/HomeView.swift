import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var planner = AIWorkoutPlanner()
    @StateObject private var dashboardViewModel = HomeDashboardViewModel()

    @State private var aiQuery: String = ""
    @State private var triggerSuggestion = false

    @Query(sort: \ActivePlan.adoptedAt, order: .reverse) private var savedPlans: [ActivePlan]
    @Query(sort: \TrainingLog.date, order: .reverse) private var trainingLogs: [TrainingLog]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 2.5) {
                    header
                    goalCard
                    metricsRow
                    activePlanCard
                    aiAssistantCard
                }
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 2)
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await dashboardViewModel.refreshHealthData() }
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(dashboardViewModel.isLoadingHealth)
                }
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .hudBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                .font(AppTypography.label(14, weight: .semibold))
                .foregroundColor(AppColors.secondary)
            Text("ホーム")
                .font(AppTypography.title(30))
                .foregroundColor(AppColors.textPrimary)
            Text("Today")
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HudSectionCard(title: "AIアシスタント", subtitle: "状況データを添えて質問すると、より具体的な提案が返ってきます。", spacing: AppLayout.grid * 1.2) {
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
                TrainingCondition.self
            ] as [any PersistentModel.Type],
            inMemory: true
        )
}
