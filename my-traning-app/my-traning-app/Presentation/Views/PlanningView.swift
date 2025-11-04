import SwiftUI

struct PlanningView: View {
    // AIプランナーをViewの状態として監視
    @StateObject private var planner = AIWorkoutPlanner()
    
    // プラン再生成をトリガーするためのState
    @State private var triggerPlanGeneration = false

    var body: some View {
        NavigationStack {
            VStack {
                if planner.isLoading {
                    // ローディング中の表示
                    ProgressView("新しいプランを生成しています...")
                        .padding()
                } else if let errorMessage = planner.errorMessage {
                    // エラーメッセージの表示
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                    }
                    .padding()
                } else if !planner.generatedPlan.isEmpty {
                    // 生成されたプランの表示
                    ScrollView {
                        Text(planner.generatedPlan)
                            .padding()
                    }
                } else {
                    // 初期表示またはプランがない場合の表示
                    Text("「再生成」ボタンを押して、新しいプランを作成してください。")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
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
        }
    }
}

#Preview {
    PlanningView()
}
