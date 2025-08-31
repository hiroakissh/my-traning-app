import SwiftUI

struct HomeView: View {
    @StateObject private var planner = AIWorkoutPlanner()
    @State private var aiQuery: String = ""
    
    // AIへの質問をトリガーするためのState
    @State private var triggerSuggestion = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 1. 今日のトレーニングプラン
                    Section(header: Text("今日のトレーニングプラン").font(.title2).bold()) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("胸の日 - 中級")
                                .font(.headline)
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("ベンチプレス: 3セット x 10回 (60kg)")
                            }
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("ダンベルフライ: 3セット x 12回 (12kg)")
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }

                    // 2. プラン進捗ウィジェット
                    Section(header: Text("プラン進捗").font(.title2).bold()) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("目標: ベンチプレス 100kg")
                            ProgressView(value: 0.6) {
                                Text("現在: 60kg (60%)")
                            }
                            Text("トレーニング継続: 25日目")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }

                    // 3. AIアシスタント
                    Section(header: Text("AIアシスタント").font(.title2).bold()) {
                        // エラーメッセージの表示
                        if let errorMessage = planner.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }

                        // AIからの返信を表示するエリア
                        if !planner.todaySuggestion.isEmpty {
                            HStack {
                                Image(systemName: "sparkle")
                                    .foregroundColor(.accentColor)
                                Text(planner.todaySuggestion)
                            }
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        TextField("今日は忙しいけど何ができる？", text: $aiQuery)
                            .textFieldStyle(.roundedBorder)
                            .disabled(planner.isLoading)
                        
                        Button(action: { triggerSuggestion = true }) {
                            if planner.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("質問する")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .disabled(planner.isLoading || aiQuery.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("記録する")
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
}

#Preview {
    HomeView()
}
