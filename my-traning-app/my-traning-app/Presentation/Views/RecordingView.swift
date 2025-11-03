import SwiftUI

struct RecordingView: View {
    private let workoutGroupsResult: Result<[WorkoutGroup], BundleDecodingError>

    @State private var selectedGroupIndex = 0
    @State private var selectedMenuItems = Set<WorkoutMenuItem>()

    init(bundle: Bundle = .main) {
        let dataResult: Result<WorkoutData, BundleDecodingError>
        do {
            let data: WorkoutData = try bundle.decode("workout_menus.json")
            dataResult = .success(data)
        } catch let decodingError as BundleDecodingError {
            dataResult = .failure(decodingError)
        } catch {
            dataResult = .failure(.dataReadFailed(file: "workout_menus.json", reason: error.localizedDescription))
        }
        self.workoutGroupsResult = dataResult.map { $0.workoutMenus }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("トレーニング記録")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch workoutGroupsResult {
        case .success(let groups):
            if groups.isEmpty {
                EmptyStateView(title: "トレーニングメニューが登録されていません。", message: "管理画面からメニューを追加してください。")
            } else {
                workoutMenuList(groups: groups)
            }
        case .failure(let error):
            EmptyStateView(title: "メニューを読み込めませんでした", message: error.localizedDescription)
                .padding()
        }
    }

    @ViewBuilder
    private func workoutMenuList(groups: [WorkoutGroup]) -> some View {
        VStack {
            let safeIndex = min(selectedGroupIndex, max(groups.count - 1, 0))
            Picker("部位", selection: $selectedGroupIndex) {
                ForEach(0..<groups.count, id: \.self) { index in
                    Text(groups[index].muscleGroup).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List(groups[safeIndex].menus, id: \.id) { item in
                Button(action: {
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
                .buttonStyle(.plain)
            }

            if !selectedMenuItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(selectedMenuItems.count)件のメニューを選択中")
                        .font(.headline)
                    Text("開始をタップすると選択したメニューで記録を始めます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button(action: {
                        // TODO: 記録開始フローの実装を追加する
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
    }
}

private struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RecordingView()
}
