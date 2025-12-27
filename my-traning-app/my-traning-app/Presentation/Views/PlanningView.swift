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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    activePlanSection
                    plannerContent
                }
                .padding()
            }
            .navigationTitle("プランニング")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // ボタンタップでプラン生成をトリガー
                        triggerPlanGeneration = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("再生成")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(planner.isLoading) // ローディング中はボタンを無効化
                }
            }
            // triggerPlanGenerationがtrueになったら非同期タスクを実行
            .task(id: triggerPlanGeneration) {
                if triggerPlanGeneration {
                    // ダミーのユーザー情報と目標でプラン生成をリクエスト
                    let dummyProfile = UserProfile(age: 30, gender: "男性", height: 175, weight: 70)
                    await planner.createPlan(userProfile: dummyProfile, goal: "3ヶ月で筋力アップを目指す")
                    
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
        }
    }

    @ViewBuilder
    private var activePlanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("アクティブプラン")
                .font(.title2)
                .bold()

            if let activePlan = savedPlans.first {
                activePlanCard(plan: activePlan)
            } else {
                Text("まだプランが採用されていません。最新の提案から選択してください。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }

    @ViewBuilder
    private var plannerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最新の提案")
                .font(.title2)
                .bold()

            if planner.isLoading {
                ProgressView("新しいプランを生成しています...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let errorMessage = planner.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemOrange).opacity(0.15))
                    .cornerRadius(12)
                }
            } else if planner.planSuggestions.isEmpty {
                Text("「再生成」ボタンを押して、新しいプランを作成してください。")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(planner.planSuggestions) { suggestion in
                        suggestionCard(suggestion)
                    }
                }
            }
        }
    }

    private func suggestionCard(_ suggestion: PlanSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(suggestion.horizon.displayName)
                    .font(.headline)
                Spacer()
                Text(suggestion.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(suggestion.title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(suggestion.detail)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(6)

            Button(action: {
                adoptPlan(from: suggestion)
            }) {
                Text("このプランを採用")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(planner.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func activePlanCard(plan: ActivePlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.horizon.displayName)
                    .font(.headline)
                Spacer()
                Text(plan.adoptedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(plan.title)
                .font(.subheadline)
                .bold()
            Text(plan.summary)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(4)
            Text(plan.detail)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
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
}

#Preview {
    PlanningView()
        .modelContainer(for: ActivePlan.self, inMemory: true)
}
