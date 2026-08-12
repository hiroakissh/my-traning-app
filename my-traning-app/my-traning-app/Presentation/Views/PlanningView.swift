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
    @State private var userProfile: UserProfile = .empty
    @State private var ageText: String = ""
    @State private var genderText: String = ""
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @State private var profileMessage: String?

    private var activePlan: ActivePlan? { savedPlans.first }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                    header

                    if let activePlan {
                        activePlanHero(plan: activePlan)
                    }

                    goalInput
                    profileSection
                    purposeChips
                    suggestedSection

                    if activePlan == nil {
                        activePlanSection
                    }
                }
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 2.5)
            }
            .hudScrollBackground()
            .navigationTitle("")
            .applyIOSNavigationBarHidden(true)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { triggerPlanGeneration = true }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(planner.isLoading)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(action: { triggerPlanGeneration = true }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                    .disabled(planner.isLoading)
                }
                #endif
            }
            // triggerPlanGenerationがtrueになったら非同期タスクを実行
            .task(id: triggerPlanGeneration) {
                if triggerPlanGeneration {
                    let prompt = buildGoalPrompt()
                    await planner.createPlan(userProfile: userProfile, goal: prompt)
                    
                    // トリガーをリセット
                    triggerPlanGeneration = false
                }
            }
            .task {
                loadUserProfile()
            }
            .alert("プラン保存に失敗しました", isPresented: Binding(get: { persistenceError != nil }, set: { _ in persistenceError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                if let persistenceError {
                    Text(persistenceError)
                }
            }
            .applyIOSNavigationBarChrome()
        }
        .hudBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text(activePlan == nil ? "AIプラン生成" : "現在のプラン")
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
                    .applyGoalTextAutocapitalization()
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

    private var profileSection: some View {
        HudSectionCard(title: "プロフィール", subtitle: "プラン生成に使う情報") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.2) {
                HStack(spacing: AppLayout.grid) {
                    profileField("年齢", text: $ageText, suffix: "歳")
                    profileField("身長", text: $heightText, suffix: "cm")
                    profileField("体重", text: $weightText, suffix: "kg")
                }

                Picker("性別", selection: $genderText) {
                    Text("選択してください").tag("")
                    Text("女性").tag("女性")
                    Text("男性").tag("男性")
                    Text("その他・回答しない").tag("その他・回答しない")
                }
                .pickerStyle(.menu)
                .tint(AppColors.primary)

                HStack {
                    if let profileMessage {
                        Text(profileMessage)
                            .font(AppTypography.label(12))
                            .foregroundColor(profileMessage == "プロフィールを保存しました。" ? AppColors.secondary : .orange)
                    }
                    Spacer()
                    Button("保存") {
                        saveUserProfile()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppColors.primary)
                }
            }
        }
    }

    private func profileField(_ title: String, text: Binding<String>, suffix: String) -> some View {
        HStack(spacing: AppLayout.grid * 0.4) {
            TextField(title, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            Text(suffix)
                .font(AppTypography.label(12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppLayout.grid)
        .padding(.vertical, AppLayout.grid * 0.9)
        .background(AppColors.surface2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
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
                if isActivePlan(suggestion) {
                    pill(text: "選択中", secondary: false)
                } else if Calendar.current.isDateInToday(suggestion.createdAt) {
                    pill(text: "RECOMMENDED", secondary: true)
                }
            }

            Text(suggestion.title)
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            PlanDetailContentView(detail: suggestion.detail, mode: .compact(maxItems: 3))

            HStack(spacing: AppLayout.grid) {
                metricChip(title: "頻度", value: frequencyText(from: suggestion.detail) ?? "調整可", systemImage: "calendar")
                metricChip(title: "強度", value: intensityText(from: suggestion.detail) ?? "フレキシブル", systemImage: "flame.fill")
            }

            Button(action: { adoptPlan(from: suggestion) }) {
                Text(isActivePlan(suggestion) ? "アクティブプラン" : "アクティブプランにする →")
                    .font(AppTypography.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(planner.isLoading || isActivePlan(suggestion))
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
            PlanDetailContentView(detail: plan.detail, mode: .compact(maxItems: 4))

            HStack(spacing: AppLayout.grid) {
                Button {
                    triggerPlanGeneration = true
                } label: {
                    Label("AIに再提案を依頼", systemImage: "sparkles")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.primary)

                Button {
                    triggerPlanGeneration = true
                } label: {
                    Label("別プランを提案", systemImage: "square.grid.2x2")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.textSecondary)
                .disabled(planner.isLoading)
            }
        }
        .padding(AppLayout.grid * 2)
        .glassCardStyle(secondary: true)
    }

    private func activePlanHero(plan: ActivePlan) -> some View {
        let progressValue = planProgressRate(for: plan)
        let progressLabel = String(format: "%.0f%%", progressValue * 100)

        return VStack(alignment: .leading, spacing: AppLayout.grid * 1.4) {
            HStack {
                pill(text: "ACTIVE PLAN", secondary: false)
                Spacer()
                pill(text: plan.horizon.displayName.uppercased(), secondary: true)
            }
            Text(plan.title)
                .font(AppTypography.body(20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(plan.summary)
                .font(AppTypography.body(14))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)

            VStack(alignment: .leading, spacing: AppLayout.grid * 0.6) {
                Text("進捗状況")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                ProgressView(value: progressValue) {
                    Text(progressLabel)
                        .font(AppTypography.body(14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.primary)
            }

            HStack(spacing: AppLayout.grid * 1.5) {
                metricChip(title: "期間", value: horizonDurationLabel(for: plan), systemImage: "calendar")
                metricChip(title: "採用日", value: plan.adoptedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                metricChip(title: "進捗", value: progressLabel, systemImage: "chart.line.uptrend.xyaxis")
            }

            Text("プラン概要")
                .font(AppTypography.body(15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            PlanDetailContentView(detail: plan.detail)

            Button {
                triggerPlanGeneration = true
            } label: {
                Label("AIに再提案を依頼", systemImage: "sparkles")
                    .font(AppTypography.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)

            HStack(spacing: AppLayout.grid) {
                Button {
                    triggerPlanGeneration = true
                } label: {
                    Label("他のプランを見る", systemImage: "square.grid.2x2")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.secondary)

                Button {
                    triggerPlanGeneration = true
                } label: {
                    Label("別プランを提案", systemImage: "square.grid.2x2")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.textSecondary)
                .disabled(planner.isLoading)
            }
        }
        .padding(AppLayout.grid * 2)
        .glassCardStyle()
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

    private func isActivePlan(_ suggestion: PlanSuggestion) -> Bool {
        guard let activePlan else { return false }
        return activePlan.title == suggestion.title
            && activePlan.summary == suggestion.summary
            && activePlan.detail == suggestion.detail
    }

    private func buildGoalPrompt() -> String {
        let trimmed = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = trimmed.isEmpty ? "3ヶ月で筋力アップを目指す" : trimmed
        return "目的: \(selectedPurpose.displayName)\n目標: \(goal)"
    }

    private func loadUserProfile() {
        let profile = UserProfileStore.load()
        userProfile = profile
        ageText = profile.age.map(String.init) ?? ""
        genderText = profile.gender ?? ""
        heightText = profile.height.map(String.init) ?? ""
        weightText = profile.weight.map(String.init) ?? ""
    }

    private func saveUserProfile() {
        let profile = UserProfile(
            age: Int(ageText),
            gender: genderText.isEmpty ? nil : genderText,
            height: Int(heightText),
            weight: Int(weightText)
        )

        guard profile.isComplete else {
            profileMessage = profile.validationMessage ?? "プロフィールを確認してください。"
            return
        }

        do {
            try UserProfileStore.save(profile)
            userProfile = profile
            profileMessage = "プロフィールを保存しました。"
        } catch {
            profileMessage = "プロフィールの保存に失敗しました。"
        }
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

    private func planProgressRate(for plan: ActivePlan) -> Double {
        let durationDays = horizonDurationDays(for: plan)
        guard durationDays > 0 else { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: plan.adoptedAt, to: Date()).day ?? 0
        let rate = Double(elapsed) / Double(durationDays)
        return min(max(rate, 0), 1)
    }

    private func horizonDurationDays(for plan: ActivePlan) -> Int {
        switch plan.horizon {
        case .shortTerm: return 21
        case .midTerm: return 42
        case .longTerm: return 90
        case .general: return 28
        }
    }

    private func horizonDurationLabel(for plan: ActivePlan) -> String {
        let days = horizonDurationDays(for: plan)
        if days % 7 == 0 {
            return "\(days / 7)週間"
        }
        return "\(days)日間"
    }
}

#Preview {
    PlanningView()
        .modelContainer(for: ActivePlan.self, inMemory: true)
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

    @ViewBuilder
    func applyGoalTextAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.sentences)
        #else
        self
        #endif
    }
}
