import SwiftUI

struct HomeView: View {
    @State private var aiQuery: String = ""

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

                    // 3. AIアシスタントへの入力窓
                    Section(header: Text("AIアシスタント").font(.title2).bold()) {
                        TextField("今日は忙しいけど何ができる？", text: $aiQuery)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {}) {
                            Text("質問する")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                    }
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .toolbar {
                // 4. 今日のトレーニング記録ボタン (ツールバーに配置)
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
        }
    }
}

#Preview {
    HomeView()
}
