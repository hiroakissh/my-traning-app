import SwiftUI

struct HomeView: View {
    @StateObject private var planner = AIWorkoutPlanner()
    @State private var aiQuery: String = ""
    
    // AIへの質問をトリガーするためのState
    @State private var triggerSuggestion = false

    private let calorieGoal: Double = 1650
    private let consumedCalories: Double = 1240
    private let sleepScore = 92
    private let sleepDuration = "8h 12m"
    private let recoveryText = "Ready to train hard."
    private let heartRate = 135.0
    private let runDistance = 5.2
    private let runCalories = 320

    var body: some View {
        NavigationStack {
            ZStack {
                homeBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 2.5) {
                        header
                        heroProgress
                        statGrid
                        aiAssistant
                        hydrationAlert
                    }
                    .padding(.horizontal, AppLayout.grid * 2.5)
                    .padding(.vertical, AppLayout.grid * 3)
                }
            }
            .navigationTitle("ホーム")
            .toolbar { EmptyView() }
            // triggerSuggestionがtrueになったら非同期タスクを実行
            .task(id: triggerSuggestion) {
                if triggerSuggestion {
                    await planner.suggestTodayWorkout(prompt: aiQuery)
                    triggerSuggestion = false
                }
            }
        }
    }

    private var homeBackground: some View {
        LinearGradient(
            colors: [
                AppColors.background,
                AppColors.background.opacity(0.8),
                AppColors.surface.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
                Text(dateString.uppercased())
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
                Text("Today")
                    .font(AppTypography.title(26))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppLayout.grid * 1.25)
                    .background(
                        Circle()
                            .fill(AppColors.surface.opacity(0.9))
                            .shadow(color: AppColors.primary.opacity(0.18), radius: 12, x: 0, y: 8)
                    )
            }
        }
    }

    private var heroProgress: some View {
        let progress = consumedCalories / calorieGoal

        return ZStack {
            RoundedRectangle(cornerRadius: AppLayout.cardRadius * 1.4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.surface.opacity(0.9),
                            AppColors.surface2.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius * 1.4, style: .continuous)
                        .stroke(AppColors.strokeGlow, lineWidth: 1)
                )
                .shadow(color: AppColors.primary.opacity(0.22), radius: 22, x: 0, y: 12)

            VStack(spacing: AppLayout.grid * 2) {
                ZStack {
                    Circle()
                        .stroke(AppColors.divider, lineWidth: 18)
                        .frame(width: 220, height: 220)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .shadow(color: AppColors.primary.opacity(0.35), radius: 14, x: 0, y: 8)

                    VStack(spacing: AppLayout.grid * 0.75) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(progress * 100))")
                                .font(AppTypography.hudNumber(42, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("%")
                                .font(AppTypography.body(18, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        Text("DAILY GOAL")
                            .font(AppTypography.label(12, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                        Text("\(Int(consumedCalories)) / \(Int(calorieGoal)) kcal")
                            .font(AppTypography.body(14, weight: .semibold))
                            .padding(.horizontal, AppLayout.grid * 2)
                            .padding(.vertical, AppLayout.grid * 0.9)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.35))
                                    .overlay(
                                        Capsule().stroke(AppColors.divider, lineWidth: 1)
                                    )
                            )
                    }
                }

                HStack(spacing: AppLayout.grid * 2) {
                    StatBubble(icon: "figure.run", text: "Morning Run", value: "\(runDistance, default: "%.1f") km", accent: Color.orange)
                    StatBubble(icon: "heart.fill", text: "Avg Heart Rate", value: "\(Int(heartRate)) bpm", accent: Color.pink)
                }
            }
            .padding(AppLayout.grid * 3)
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppLayout.grid * 1.5), count: 2), spacing: AppLayout.grid * 1.5) {
            StatCard(
                icon: "figure.run",
                iconColor: Color.orange,
                title: "Morning Run",
                value: String(format: "%.1f", runDistance),
                unit: "KM",
                footer: "• \(Int(runCalories)) kcal",
                footerColor: Color.orange.opacity(0.9)
            )
            StatCard(
                icon: "heart.fill",
                iconColor: Color.pink,
                title: "Avg Heart Rate",
                value: "\(Int(heartRate))",
                unit: "bpm",
                footerBarProgress: 0.58
            )
            StatCard(
                icon: "moon.fill",
                iconColor: Color.purple,
                title: "Sleep Score",
                value: "\(sleepScore)",
                unit: sleepDuration,
                badge: "+5%"
            )
            StatCard(
                icon: "bolt.heart",
                iconColor: AppColors.primary,
                title: "Recovery",
                value: "Ready to",
                unit: "train hard.",
                isTwoLineValue: true
            )
        }
    }

    private var aiAssistant: some View {
        HudSectionCard(title: "AI Assistant", subtitle: "短く尋ねるほど冴えた提案に") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
                if let errorMessage = planner.errorMessage {
                    HStack(alignment: .top, spacing: AppLayout.grid) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.secondary)
                        Text(errorMessage)
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                HStack(spacing: AppLayout.grid) {
                    HStack(spacing: AppLayout.grid) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)
                        TextField("Ask about your plan...", text: $aiQuery)
                            .foregroundColor(AppColors.textPrimary)
                            .disabled(planner.isLoading)
                    }
                    .padding(.horizontal, AppLayout.grid * 1.5)
                    .padding(.vertical, AppLayout.grid * 1.1)
                    .background(
                        Capsule()
                            .fill(AppColors.surface2.opacity(0.92))
                            .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
                    )

                    Button(action: { triggerSuggestion = true }) {
                        Text("Ask")
                            .font(AppTypography.body(15, weight: .semibold))
                            .padding(.horizontal, AppLayout.grid * 2)
                            .padding(.vertical, AppLayout.grid * 1.1)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primary, AppColors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(AppColors.background)
                    }
                    .disabled(planner.isLoading || aiQuery.isEmpty)
                    .opacity(planner.isLoading || aiQuery.isEmpty ? 0.7 : 1)
                }

                if planner.isLoading {
                    ProgressView()
                        .tint(AppColors.primary)
                } else if !planner.todaySuggestion.isEmpty {
                    HStack(alignment: .top, spacing: AppLayout.grid) {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppColors.primary)
                        Text(planner.todaySuggestion)
                            .font(AppTypography.body(15))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
    }

    private var hydrationAlert: some View {
        HudSectionCard(useSecondarySurface: true) {
            HStack(spacing: AppLayout.grid * 1.25) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(AppColors.strokeGlow, lineWidth: 1))
                    Image(systemName: "drop.fill")
                        .foregroundColor(Color.blue.opacity(0.85))
                }

                VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
                    Text("Hydration Alert")
                        .font(AppTypography.body(16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("You're slightly behind schedule.")
                        .font(AppTypography.label(12))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(AppLayout.grid * 1.1)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.35))
                                .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 8)
                        )
                }
            }
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Subviews

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    var badge: String? = nil
    var footer: String? = nil
    var footerColor: Color? = nil
    var footerBarProgress: Double? = nil
    var isTwoLineValue: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.1) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                Spacer()
                if let badge {
                    Text(badge)
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, AppLayout.grid)
                        .padding(.vertical, AppLayout.grid * 0.5)
                        .background(
                            Capsule()
                                .fill(AppColors.primary.opacity(0.14))
                        )
                }
            }

            Text(title)
                .font(AppTypography.body(14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            if isTwoLineValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(AppTypography.body(13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                    Text(unit)
                        .font(AppTypography.body(16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(AppTypography.title(24))
                        .foregroundColor(AppColors.textPrimary)
                    Text(unit)
                        .font(AppTypography.label(12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            if let footer {
                HStack(spacing: 6) {
                    Circle()
                        .fill((footerColor ?? AppColors.textSecondary).opacity(0.9))
                        .frame(width: 6, height: 6)
                    Text(footer)
                        .font(AppTypography.label(12))
                        .foregroundColor(footerColor ?? AppColors.textSecondary)
                }
            }

            if let footerBarProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.surface2.opacity(0.9))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * footerBarProgress))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(AppLayout.grid * 2)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.16), radius: 16, x: 0, y: 12)
        )
    }
}

private struct StatBubble: View {
    let icon: String
    let text: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: AppLayout.grid * 1.25) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
                Text(text)
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(value)
                    .font(AppTypography.body(15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, AppLayout.grid * 1.5)
        .padding(.vertical, AppLayout.grid * 1.25)
        .background(
            Capsule()
                .fill(AppColors.surface2.opacity(0.9))
                .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.16), radius: 10, x: 0, y: 6)
        )
    }
}

#Preview {
    HomeView()
}
