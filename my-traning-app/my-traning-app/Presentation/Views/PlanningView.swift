import SwiftUI

struct PlanningView: View {
    // AIプランナーをViewの状態として監視
    @StateObject private var planner = AIWorkoutPlanner()
    
    // プラン再生成をトリガーするためのState
    @State private var triggerPlanGeneration = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: AppLayout.grid * 2) {
                    HudSectionCard(title: "AIプランナー", subtitle: "静かに練ったプランを受け取る") {
                        if planner.isLoading {
                            ProgressView("新しいプランを生成しています...")
                                .tint(AppColors.primary)
                                .foregroundColor(AppColors.textSecondary)
                        } else if let errorMessage = planner.errorMessage {
                            VStack(spacing: AppLayout.grid * 1.25) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(AppColors.secondary)
                                Text(errorMessage)
                                    .multilineTextAlignment(.center)
                                    .font(AppTypography.body(15))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        } else if !planner.generatedPlan.isEmpty {
                            ScrollView {
                                Text(planner.generatedPlan)
                                    .font(AppTypography.body())
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, AppLayout.grid)
                            }
                            .frame(maxHeight: 320)
                        } else {
                            Text("「再生成」ボタンを押して、新しいプランを作成してください。")
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .font(AppTypography.body())
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AppLayout.grid * 2.5)
                .padding(.vertical, AppLayout.grid * 3)
            }
            .navigationTitle("プランニング")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // ボタンタップでプラン生成をトリガー
                        triggerPlanGeneration = true
                    }) {
                        HStack(spacing: AppLayout.grid) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("再生成")
                                .font(AppTypography.body(15, weight: .semibold))
                        }
                        .padding(.horizontal, AppLayout.grid * 1.5)
                        .padding(.vertical, AppLayout.grid)
                        .background(AppColors.primary.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous))
                    }
                    .tint(AppColors.primary)
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
        }
    }
}

#Preview {
    PlanningView()
}
