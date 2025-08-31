import SwiftUI

struct RecordingView: View {
    // 1. 正しいルートオブジェクト(WorkoutData)でデコードし、その中の配列を使用する
    let workoutGroups: [WorkoutGroup] = (Bundle.main.decode("workout_menus.json") as WorkoutData).workoutMenus
    
    @State private var selectedGroupIndex = 0
    @State private var selectedMenuItems = Set<WorkoutMenuItem>()
    
    var body: some View {
        NavigationStack {
            VStack {
                // 2. 部位を選択するPicker
                Picker("部位", selection: $selectedGroupIndex) {
                    ForEach(0..<workoutGroups.count, id: \.self) { index in
                        Text(workoutGroups[index].muscleGroup).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 3. 選択された部位のメニュー一覧
                List(workoutGroups[selectedGroupIndex].menus, id: \.name) { item in
                    Button(action: {
                        // メニューを選択/選択解除する
                        if selectedMenuItems.contains(item) {
                            selectedMenuItems.remove(item)
                        } else {
                            selectedMenuItems.insert(item)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedMenuItems.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain) // Listのデフォルトスタイルを上書き
                }
                
                // 4. 選択されたメニューの表示と記録開始ボタン
                if !selectedMenuItems.isEmpty {
                    VStack {
                        Text("\(selectedMenuItems.count)件のメニューを選択中")
                            .font(.headline)
                        Button(action: {
                            // 選択したメニューで記録を開始するロジック
                        }) {
                            Text("記録を開始")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("トレーニング記録")
        }
    }
}

#Preview {
    RecordingView()
}
