import SwiftUI
import SwiftData

struct TodayRecommendationView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recommendation: DailyRecommendation

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                header
                reasonsSection
                menuSection
                recoverySection
                actionsSection
            }
            .padding(.horizontal, AppLayout.grid * 2)
            .padding(.vertical, AppLayout.grid * 2.5)
        }
        .hudScrollBackground()
        .navigationTitle("")
        .applyIOSNavigationBarHidden(true)
    }

    private var header: some View {
        HudSectionCard(title: nil, subtitle: nil, spacing: AppLayout.grid * 1.4) {
            HStack(spacing: AppLayout.grid) {
                Image(systemName: recommendation.readinessLevel.systemImage)
                    .foregroundColor(AppColors.primary)
                Text(recommendation.readinessLevel.displayName)
                    .font(AppTypography.label(13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(recommendation.recommendationType.displayName)
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }

            Text("今日の提案：\(recommendation.title)")
                .font(AppTypography.title(24))
                .foregroundColor(AppColors.textPrimary)

            Text(recommendation.summary)
                .font(AppTypography.body(15))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reasonsSection: some View {
        HudSectionCard(title: "理由", subtitle: nil, spacing: AppLayout.grid) {
            VStack(alignment: .leading, spacing: AppLayout.grid) {
                ForEach(recommendation.reasons, id: \.self) { reason in
                    Label(reason, systemImage: "checkmark.circle.fill")
                        .font(AppTypography.body(14))
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var menuSection: some View {
        HudSectionCard(title: "メニュー", subtitle: nil, spacing: AppLayout.grid) {
            VStack(spacing: AppLayout.grid) {
                ForEach(sortedExercises) { exercise in
                    HStack(alignment: .top, spacing: AppLayout.grid) {
                        Text("\(exercise.order)")
                            .font(AppTypography.label(12, weight: .semibold))
                            .foregroundColor(AppColors.background)
                            .frame(width: 24, height: 24)
                            .background(AppColors.primary)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
                            HStack {
                                Text(exercise.name)
                                    .font(AppTypography.body(15, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if exercise.estimatedMinutes > 0 {
                                    Text("\(exercise.estimatedMinutes)分")
                                        .font(AppTypography.label(12, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }

                            Text(exercise.detail)
                                .font(AppTypography.label())
                                .foregroundColor(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            exerciseTargetText(exercise)
                                .font(AppTypography.label(12, weight: .semibold))
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                    .padding(AppLayout.grid * 1.2)
                    .background(AppColors.surface2.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
                }
            }
        }
    }

    private var recoverySection: some View {
        HudSectionCard(title: recommendation.recommendationType == .rest ? "今日やること" : "回復アドバイス", subtitle: nil, spacing: AppLayout.grid) {
            VStack(alignment: .leading, spacing: AppLayout.grid) {
                ForEach(recommendation.recoveryAdvice, id: \.self) { advice in
                    Label(advice, systemImage: recommendation.recommendationType == .rest ? "moon.zzz.fill" : "heart.fill")
                        .font(AppTypography.body(14))
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var actionsSection: some View {
        HudSectionCard(title: "選択肢", subtitle: nil, spacing: AppLayout.grid) {
            VStack(spacing: AppLayout.grid) {
                if recommendation.recommendationType != .rest {
                    NavigationLink(destination: RecordingView()) {
                        Label("このメニューで開始", systemImage: "play.fill")
                            .font(AppTypography.body(16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .simultaneousGesture(TapGesture().onEnded {
                        accept(.startedOriginalPlan)
                    })
                }

                ForEach(recommendation.alternatives) { alternative in
                    Button(action: { accept(action(for: alternative)) }) {
                        HStack(spacing: AppLayout.grid) {
                            Image(systemName: icon(for: alternative))
                            VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
                                Text(alternative.title)
                                    .font(AppTypography.body(14, weight: .semibold))
                                Text(alternative.planDescription)
                                    .font(AppTypography.label(12))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if alternative.estimatedMinutes > 0 {
                                Text("\(alternative.estimatedMinutes)分")
                                    .font(AppTypography.label(12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .padding(AppLayout.grid * 1.2)
                        .background(AppColors.surface2.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { accept(.changedToRest) }) {
                    Label("今日は休養日にする", systemImage: "moon.zzz.fill")
                        .font(AppTypography.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.textSecondary)
            }
        }
    }

    private var sortedExercises: [PlannedExercise] {
        recommendation.plannedExercises.sorted { $0.order < $1.order }
    }

    private func exerciseTargetText(_ exercise: PlannedExercise) -> Text {
        var parts: [String] = []
        if let weight = exercise.weightDescription {
            parts.append(weight)
        }
        if let sets = exercise.targetSets, let reps = exercise.targetReps {
            parts.append("\(sets)セット x \(reps)回")
        } else if let sets = exercise.targetSets {
            parts.append("\(sets)セット")
        } else if let reps = exercise.targetReps {
            parts.append("\(reps)回")
        }
        if parts.isEmpty {
            parts.append(exercise.category.displayName)
        }
        return Text(parts.joined(separator: " / "))
    }

    private func accept(_ action: AcceptedAction) {
        recommendation.acceptedAction = action
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save accepted action: \(error.localizedDescription)")
        }
    }

    private func action(for alternative: AlternativePlan) -> AcceptedAction {
        if alternative.estimatedMinutes == 0 || alternative.title.contains("休養") || alternative.title.contains("休") {
            return .changedToRest
        }
        if alternative.title.contains("短縮") || alternative.title.contains("10分") || alternative.title.contains("20分") {
            return .startedShortPlan
        }
        if alternative.title.contains("相談") || alternative.title.contains("別") {
            return .requestedAnotherPlan
        }
        return .startedOriginalPlan
    }

    private func icon(for alternative: AlternativePlan) -> String {
        switch action(for: alternative) {
        case .startedOriginalPlan: return "play.circle.fill"
        case .startedShortPlan: return "forward.end.circle.fill"
        case .changedToRest: return "moon.zzz.fill"
        case .requestedAnotherPlan: return "sparkles"
        case .skipped: return "xmark.circle.fill"
        }
    }
}

#Preview {
    let recommendation = DailyRecommendation(
        readinessLevel: .easy,
        recommendationType: .lightWorkout,
        title: "上半身ライト",
        summary: "今日は軽めがおすすめです。フォーム確認と短い有酸素で継続を優先します。",
        reasons: ["睡眠が短めです。", "昨日の疲労が残っている可能性があります。", "今週の継続を優先します。"],
        plannedExercises: [
            PlannedExercise(order: 1, name: "ベンチプレス", detail: "重量を追わずフォーム確認", targetSets: 3, targetReps: 8, weightDescription: "軽め", estimatedMinutes: 12, category: .strength),
            PlannedExercise(order: 2, name: "有酸素", detail: "息が上がりすぎない強度", estimatedMinutes: 10, category: .cardio)
        ],
        alternatives: [
            AlternativePlan(title: "10分版に短縮", description: "最初の1種目だけ実行する", estimatedMinutes: 10, intensity: 2),
            AlternativePlan(title: "今日は休養にする", description: "疲労が強い場合は休養として記録する", estimatedMinutes: 0, intensity: 1)
        ],
        recoveryAdvice: ["終わった後に余力が残る強度で止めます。", "痛みがある動きは避けてください。"]
    )

    NavigationStack {
        TodayRecommendationView(recommendation: recommendation)
    }
    .modelContainer(
        for: [
            DailyRecommendation.self,
            PlannedExercise.self,
            AlternativePlan.self,
            TrainingLog.self,
            TrainingExercise.self,
            TrainingSet.self,
            TrainingCondition.self
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
