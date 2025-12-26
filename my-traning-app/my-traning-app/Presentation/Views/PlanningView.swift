import SwiftUI

struct PlanningView: View {
    @StateObject private var planner = AIWorkoutPlanner()

    @State private var aiQuery: String = ""
    @State private var selectedTags: Set<String> = ["筋肥大"]
    @State private var activePlan: PlanDetail? = nil
    @State private var suggestions: [PlanSuggestion] = PlanSuggestion.mock
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 2.5) {
                        header

                        if let activePlan {
                            ActivePlanCard(plan: activePlan, onRegenerate: requestRegenerate, onSeeOthers: showSuggestions, onChangePlan: showSuggestions)
                        } else {
                            newGoalSection
                            suggestedSection
                        }

                        Spacer(minLength: AppLayout.grid * 5)
                    }
                    .padding(.horizontal, AppLayout.grid * 2.5)
                    .padding(.vertical, AppLayout.grid * 3)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Sections

    private var background: some View {
        LinearGradient(
            colors: [
                AppColors.background,
                AppColors.surface.opacity(0.9)
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
                    .padding(AppLayout.grid * 1.2)
                    .background(Circle().stroke(AppColors.divider, lineWidth: 1))
            }
            Spacer()
            Text(activePlan == nil ? "AIプラン生成" : "現在のプラン")
                .font(AppTypography.title(20))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: requestRegenerate) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(AppColors.textSecondary)
                    .padding(AppLayout.grid * 1.2)
                    .background(Circle().stroke(AppColors.divider, lineWidth: 1))
            }
        }
    }

    private var newGoalSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            HStack(spacing: AppLayout.grid) {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.primary)
                Text("新しい目標を設定")
                    .font(AppTypography.title(20))
                    .foregroundColor(AppColors.textPrimary)
            }

            HStack(spacing: AppLayout.grid) {
                TextField("例: 夏までに腹筋を割りたい…", text: $aiQuery)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppLayout.grid * 1.25)
                    .padding(.vertical, AppLayout.grid * 1.1)
                Button(action: requestSuggestions) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.background)
                        .padding(AppLayout.grid * 1.25)
                        .background(Circle().fill(AppColors.primary))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                    .fill(AppColors.surface.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
            )

            tagChips
        }
    }

    private var tagChips: some View {
        let tags = ["高強度 HIIT", "持久力アップ", "筋肥大", "減量", "体幹"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.grid) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    } label: {
                        HStack(spacing: AppLayout.grid * 0.6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(tag)
                                .font(AppTypography.label(12, weight: .semibold))
                        }
                        .padding(.horizontal, AppLayout.grid * 1.4)
                        .padding(.vertical, AppLayout.grid * 0.9)
                        .background(
                            Capsule()
                                .fill(selectedTags.contains(tag) ? AppColors.primary : AppColors.surface.opacity(0.85))
                                .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
                        )
                        .foregroundColor(selectedTags.contains(tag) ? AppColors.background : AppColors.textSecondary)
                    }
                }
            }
        }
    }

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            HStack {
                Text("提案されたプラン")
                    .font(AppTypography.title(18))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(suggestions.count)件の新規提案")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }

            VStack(spacing: AppLayout.grid * 1.5) {
                ForEach(suggestions) { suggestion in
                    PlanSuggestionCard(suggestion: suggestion) {
                        adopt(plan: suggestion)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func requestSuggestions() {
        isLoading = true
        Task {
            defer { isLoading = false }
            await planner.suggestTodayWorkout(prompt: aiQuery.isEmpty ? "カスタムプラン提案" : aiQuery)
            // keep mock suggestions for now
        }
    }

    private func requestRegenerate() {
        requestSuggestions()
    }

    private func adopt(plan: PlanSuggestion) {
        activePlan = PlanDetail(
            title: plan.title,
            subtitle: plan.subtitle,
            weeks: plan.weeks,
            focus: plan.focus,
            frequencyPerWeek: plan.frequency,
            progress: 0.42,
            generatedTag: plan.badges.first ?? "AI GENERATED"
        )
    }

    private func showSuggestions() {
        activePlan = nil
    }
}

// MARK: - Models

private struct PlanSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let badges: [String]
    let focus: String
    let frequency: String
    let intensity: String?
    let weeks: String

    static let mock: [PlanSuggestion] = [
        PlanSuggestion(
            title: "筋肥大 プッシュ/プル",
            subtitle: "上半身のボリュームアップに集中し、主要な筋肉群を刺激します。",
            badges: ["RECOMMENDED", "HARD"],
            focus: "筋肥大",
            frequency: "週4回",
            intensity: "高強度",
            weeks: "8週間"
        ),
        PlanSuggestion(
            title: "週間持久力プラン",
            subtitle: "HIITと有酸素運動のミックスで心肺機能を効率的に強化します。",
            badges: ["ENDURANCE"],
            focus: "持久力",
            frequency: "週5回",
            intensity: nil,
            weeks: "6週間"
        )
    ]
}

private struct PlanDetail {
    let title: String
    let subtitle: String
    let weeks: String
    let focus: String
    let frequencyPerWeek: String
    let progress: Double
    let generatedTag: String
}

// MARK: - Components

private struct PlanSuggestionCard: View {
    let suggestion: PlanSuggestion
    let onAdopt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
            HStack(spacing: AppLayout.grid * 0.75) {
                ForEach(suggestion.badges, id: \.self) { badge in
                    Text(badge)
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.background)
                        .padding(.horizontal, AppLayout.grid * 1.1)
                        .padding(.vertical, AppLayout.grid * 0.6)
                        .background(
                            Capsule()
                                .fill(badge == "HARD" ? AppColors.secondary : AppColors.primary)
                        )
                }
            }

            Text(suggestion.title)
                .font(AppTypography.title(20))
                .foregroundColor(AppColors.textPrimary)
            Text(suggestion.subtitle)
                .font(AppTypography.body(14))
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: AppLayout.grid * 1.25) {
                StatPill(icon: "calendar", title: "頻度", value: suggestion.frequency)
                StatPill(icon: "flame.fill", title: "強度", value: suggestion.intensity ?? "調整可")
            }

            Button(action: onAdopt) {
                Text("プランを採用 →")
                    .font(AppTypography.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppLayout.grid * 1.4)
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                            .fill(AppColors.primary)
                    )
                    .foregroundColor(AppColors.background)
            }
        }
        .padding(AppLayout.grid * 1.75)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.18), radius: 16, x: 0, y: 10)
        )
    }
}

private struct ActivePlanCard: View {
    let plan: PlanDetail
    let onRegenerate: () -> Void
    let onSeeOthers: () -> Void
    let onChangePlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            HStack(spacing: AppLayout.grid) {
                Label("ACTIVE PLAN", systemImage: "circle.fill")
                    .foregroundColor(AppColors.primary)
                    .font(AppTypography.label(12, weight: .semibold))
                Spacer()
                Text(plan.generatedTag)
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppLayout.grid * 1.2)
                    .padding(.vertical, AppLayout.grid * 0.6)
                    .background(RoundedRectangle(cornerRadius: AppLayout.buttonRadius).fill(AppColors.surface2.opacity(0.8)))
            }

            Text(plan.title)
                .font(AppTypography.title(24))
                .foregroundColor(AppColors.textPrimary)
            Text(plan.subtitle)
                .font(AppTypography.body(14))
                .foregroundColor(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                Text("進捗状況")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                ProgressView(value: plan.progress) {
                    EmptyView()
                }
                .tint(AppColors.primary)
                Text("\(Int(plan.progress * 100))%")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }

            HStack(spacing: AppLayout.grid * 1.0) {
                StatTile(icon: "calendar", title: "期間", value: plan.weeks)
                StatTile(icon: "dot.radiowaves.left.and.right", title: "フォーカス", value: plan.focus)
                StatTile(icon: "repeat", title: "頻度", value: plan.frequencyPerWeek)
            }

            VStack(alignment: .leading, spacing: AppLayout.grid * 1.0) {
                Text("プラン概要")
                    .font(AppTypography.body(16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("HIITと長距離ランニングを組み合わせ、心肺機能の最大化を目指します。週2回の自重トレーニングで体幹も同時に強化する総合プログラムです。")
                    .font(AppTypography.body(14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, AppLayout.grid * 0.5)
            }
            .padding(AppLayout.grid * 1.25)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .fill(AppColors.surface.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
            )

            VStack(spacing: AppLayout.grid * 1.25) {
                Button(action: onRegenerate) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("AIに再提案を依頼")
                            .font(AppTypography.body(16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppLayout.grid * 1.4)
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                            .stroke(AppColors.primary, lineWidth: 1.5)
                    )
                    .foregroundColor(AppColors.primary)
                }

                HStack(spacing: AppLayout.grid * 1.25) {
                    ActionTile(icon: "rectangle.grid.2x2", title: "他のプランを見る", action: onSeeOthers)
                    ActionTile(icon: "pencil.and.list.clipboard", title: "プランを変更", action: onChangePlan)
                }
            }
        }
        .padding(AppLayout.grid * 2)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.18), radius: 16, x: 0, y: 10)
        )
    }
}

private struct StatPill: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
            Label(title, systemImage: icon)
                .font(AppTypography.label(12))
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.body(15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppLayout.grid * 1.1)
        .padding(.horizontal, AppLayout.grid * 1.2)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                .fill(AppColors.surface2.opacity(0.9))
        )
    }
}

private struct StatTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Label(title, systemImage: icon)
                .font(AppTypography.label(12))
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.body(16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppLayout.grid * 1.4)
        .padding(.horizontal, AppLayout.grid * 1.2)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.9))
        )
    }
}

private struct ActionTile: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppLayout.grid * 0.8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(AppTypography.body(14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppLayout.grid * 1.5)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .fill(AppColors.surface.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
            )
            .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    PlanningView()
}
