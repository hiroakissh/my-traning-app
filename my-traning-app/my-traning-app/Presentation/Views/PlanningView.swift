import SwiftUI
import SwiftData

struct PlanningView: View {
    // AIプランナーをViewの状態として監視
    @StateObject private var planner = AIWorkoutPlanner()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivePlan.adoptedAt, order: .reverse) private var savedPlans: [ActivePlan]
    
    // プラン再生成をトリガーするためのState
    @State private var triggerPlanGeneration = false
    @State private var persistenceError: String?

    @State private var goalText: String = ""
    @State private var selectedPurpose: TrainingPurpose = .hypertrophy

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                    header
                    goalInput
                    purposeChips
                    suggestedSection
                    activePlanSection
                }
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 2.5)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { triggerPlanGeneration = true }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(planner.isLoading)
                }
            }
            // triggerPlanGenerationがtrueになったら非同期タスクを実行
            .task(id: triggerPlanGeneration) {
                if triggerPlanGeneration {
                    let dummyProfile = UserProfile(age: 30, gender: "男性", height: 175, weight: 70)
                    let prompt = buildGoalPrompt()
                    await planner.createPlan(userProfile: dummyProfile, goal: prompt)
                    
                    // トリガーをリセット
                    triggerPlanGeneration = false
                }
            }
            .alert("プラン保存に失敗しました", isPresented: Binding(get: { persistenceError != nil }, set: { _ in persistenceError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                if let persistenceError {
                    Text(persistenceError)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .hudBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text(Date().formatted(.dateTime.hour().minute()))
                .font(AppTypography.label(13, weight: .semibold))
                .foregroundColor(AppColors.secondary)
            Text("AIプラン生成")
                .font(AppTypography.title(26))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalInput: some View {
        HudSectionCard(title: "新しい目標を設定", subtitle: nil, spacing: AppLayout.grid * 1.2) {
            HStack(spacing: AppLayout.grid) {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.primary)
                TextField("3ヶ月でベンチプレスを100kgにしたい", text: $goalText)
                    .foregroundColor(AppColors.textPrimary)
                    .textInputAutocapitalization(.sentences)
                Button(action: { triggerPlanGeneration = true }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.primary)
                }
                .disabled(planner.isLoading)
            }
            .padding(.vertical, AppLayout.grid * 1.25)
            .padding(.horizontal, AppLayout.grid * 1.5)
            .background(AppColors.surface2.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .stroke(AppColors.strokeGlow, lineWidth: 1)
            )
        }
    }

    private var purposeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.grid) {
                ForEach(TrainingPurpose.allCases, id: \.self) { purpose in
                    Button(action: { selectedPurpose = purpose }) {
                        Text(purpose.displayName)
                            .font(AppTypography.label(13, weight: .semibold))
                            .padding(.horizontal, AppLayout.grid * 2)
                            .padding(.vertical, AppLayout.grid * 0.8)
                            .background(
                                Capsule().fill(purpose == selectedPurpose ? AppColors.primary : AppColors.surface2)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.strokeGlow, lineWidth: 1)
                            )
                            .foregroundColor(purpose == selectedPurpose ? AppColors.background : AppColors.textSecondary)
                    }
                }
            }
            .padding(.vertical, AppLayout.grid * 0.5)
        }
    }

    @ViewBuilder
    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            HStack {
                Text("提案されたプラン")
                    .font(AppTypography.body(17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if planner.planSuggestions.isEmpty == false {
                    Text("\(planner.planSuggestions.count)件の新規提案")
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.secondary)
                }
            }

            if planner.isLoading {
                ProgressView("新しいプランを生成しています...")
                    .tint(AppColors.primary)
            } else if let errorMessage = planner.errorMessage {
                HStack(alignment: .top, spacing: AppLayout.grid) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(AppColors.surface.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
            } else if planner.planSuggestions.isEmpty {
                Text("目標を入力して「↑」をタップするとプランを提案します。")
                    .font(AppTypography.label())
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, AppLayout.grid)
            } else {
                VStack(spacing: AppLayout.grid * 1.5) {
                    ForEach(planner.planSuggestions) { suggestion in
                        suggestionCard(suggestion)
                    }
                }
            }
        }
    }

    private func suggestionCard(_ suggestion: PlanSuggestion) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.2) {
            HStack(spacing: AppLayout.grid) {
                pill(text: suggestion.horizon.displayName.uppercased())
                if Calendar.current.isDateInToday(suggestion.createdAt) {
                    pill(text: "RECOMMENDED", secondary: true)
                }
            }

            Text(suggestion.title)
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Text(suggestion.detail)
                .font(AppTypography.body(14))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(4)

            HStack(spacing: AppLayout.grid) {
                metricChip(title: "頻度", value: frequencyText(from: suggestion.detail) ?? "調整可", systemImage: "calendar")
                metricChip(title: "強度", value: intensityText(from: suggestion.detail) ?? "フレキシブル", systemImage: "flame.fill")
            }

            Button(action: { adoptPlan(from: suggestion) }) {
                Text("プランを採用 →")
                    .font(AppTypography.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(planner.isLoading)
        }
        .padding(AppLayout.grid * 2)
        .glassCardStyle()
    }

    private func pill(text: String, secondary: Bool = false) -> some View {
        Text(text)
            .font(AppTypography.label(12, weight: .semibold))
            .padding(.horizontal, AppLayout.grid * 1.5)
            .padding(.vertical, AppLayout.grid * 0.7)
            .background(secondary ? AppColors.surface2 : AppColors.primary)
            .foregroundColor(secondary ? AppColors.textPrimary : AppColors.background)
            .clipShape(Capsule())
    }

    private func metricChip(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
            HStack(spacing: AppLayout.grid * 0.8) {
                Image(systemName: systemImage)
                    .foregroundColor(AppColors.primary)
                Text(title)
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            Text(value)
                .font(AppTypography.body(15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.surface2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var activePlanSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid) {
            Text("アクティブプラン")
                .font(AppTypography.body(17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            if let activePlan = savedPlans.first {
                activePlanCard(plan: activePlan)
            } else {
                Text("まだプランが採用されていません。最新の提案から選択してください。")
                    .font(AppTypography.label())
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
                    .glassCardStyle(secondary: true)
            }
        }
    }

    private func activePlanCard(plan: ActivePlan) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid) {
            HStack(spacing: AppLayout.grid) {
                pill(text: plan.horizon.displayName.uppercased(), secondary: true)
                Text(plan.adoptedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.label(12))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            }
            Text(plan.title)
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(plan.summary)
                .font(AppTypography.label())
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)
            Text(plan.detail)
                .font(AppTypography.label())
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(5)
        }
        .padding(AppLayout.grid * 2)
        .glassCardStyle(secondary: true)
    }

    private func adoptPlan(from suggestion: PlanSuggestion) {
        let plan = ActivePlan(
            horizon: suggestion.horizon,
            title: suggestion.title,
            summary: suggestion.summary,
            detail: suggestion.detail,
            sourcePrompt: suggestion.sourcePrompt
        )
        modelContext.insert(plan)
        do {
            try modelContext.save()
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func buildGoalPrompt() -> String {
        let trimmed = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = trimmed.isEmpty ? "3ヶ月で筋力アップを目指す" : trimmed
        return "目的: \(selectedPurpose.displayName)\n目標: \(goal)"
    }

    private func frequencyText(from text: String) -> String? {
        let pattern = "週\\s*([0-9]+)\\s*回"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }

    private func intensityText(from text: String) -> String? {
        if text.contains("高強度") { return "高強度" }
        if text.contains("中強度") { return "中強度" }
        if text.contains("低強度") { return "低強度" }
        return nil
    }
}

#Preview {
    PlanningView()
        .modelContainer(for: ActivePlan.self, inMemory: true)
}
