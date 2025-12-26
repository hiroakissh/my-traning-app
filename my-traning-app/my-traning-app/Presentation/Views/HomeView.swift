import SwiftUI

struct HomeView: View {
    @StateObject private var planner = AIWorkoutPlanner()
    @State private var aiQuery: String = ""
    
    // AIへの質問をトリガーするためのState
    @State private var triggerSuggestion = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                        HudSectionCard(title: "今日のトレーニングプラン", subtitle: "今夜のセッションで集中したい部位") {
                            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                                Text("胸の日 - 中級")
                                    .font(AppTypography.title(20))
                                    .foregroundColor(AppColors.textPrimary)
                                planRow(icon: "flame.fill", text: "ベンチプレス: 3セット x 10回 (60kg)")
                                planRow(icon: "flame.fill", text: "ダンベルフライ: 3セット x 12回 (12kg)")
                            }
                        }

                        HudSectionCard(title: "プラン進捗", subtitle: "静かなHUDで淡々とチェック") {
                            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                                Text("目標: ベンチプレス 100kg")
                                    .font(AppTypography.body(16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                ProgressView(value: 0.6) {
                                    Text("現在: 60kg (60%)")
                                        .font(AppTypography.label(13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .tint(AppColors.primary)
                                Text("トレーニング継続: 25日目")
                                    .font(AppTypography.label(12))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        HudSectionCard(title: "AIアシスタント", subtitle: "短く尋ねるほど冴えた提案に") {
                            if let errorMessage = planner.errorMessage {
                                HStack(alignment: .top, spacing: AppLayout.grid) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.secondary)
                                    Text(errorMessage)
                                        .font(AppTypography.label(12))
                                        .foregroundColor(AppColors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(AppLayout.grid * 1.25)
                                .background(AppColors.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous))
                            }

                            if !planner.todaySuggestion.isEmpty {
                                HStack(alignment: .top, spacing: AppLayout.grid) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(AppColors.primary)
                                    Text(planner.todaySuggestion)
                                        .font(AppTypography.body(15))
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .padding(AppLayout.grid * 1.25)
                                .background(AppColors.primary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
                            }
                            
                            TextField("今日は忙しいけど何ができる？", text: $aiQuery)
                                .hudFieldStyle()
                                .disabled(planner.isLoading)
                            
                            Button(action: { triggerSuggestion = true }) {
                                if planner.isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("質問する")
                                        .font(AppTypography.body(16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                            .tint(AppColors.primary)
                            .disabled(planner.isLoading || aiQuery.isEmpty)
                        }
                    }
                    .padding(.horizontal, AppLayout.grid * 2.5)
                    .padding(.vertical, AppLayout.grid * 3)
                }
            }
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        HStack(spacing: AppLayout.grid) {
                            Image(systemName: "plus.circle.fill")
                            Text("記録する")
                                .font(AppTypography.body(15, weight: .semibold))
                        }
                        .padding(.horizontal, AppLayout.grid * 1.5)
                        .padding(.vertical, AppLayout.grid)
                        .background(AppColors.primary.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous))
                    }
                    .tint(AppColors.primary)
                }
            }
            // triggerSuggestionがtrueになったら非同期タスクを実行
            .task(id: triggerSuggestion) {
                if triggerSuggestion {
                    await planner.suggestTodayWorkout(prompt: aiQuery)
                    triggerSuggestion = false
                }
            }
        }
    }

    private func planRow(icon: String, text: String) -> some View {
        HStack(spacing: AppLayout.grid) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
            Text(text)
                .font(AppTypography.body())
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    HomeView()
}
