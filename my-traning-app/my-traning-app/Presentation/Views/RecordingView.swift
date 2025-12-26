import SwiftUI

struct RecordingView: View {
    private let workoutGroupsResult: Result<[WorkoutGroup], BundleDecodingError>
    private let healthDataProvider: HealthDataProviding

    @State private var selectedDate = Date()
    @State private var selectedGroupIndex = 0
    @State private var selectedMenuItems = Set<WorkoutMenuItem>()
    @State private var strengthInputs: [StrengthExerciseInput] = []
    @State private var cardioInput = CardioInput()
    @State private var sessionStartDate: Date?
    @State private var healthSnapshot: HealthDataSnapshot?
    @State private var isFetchingHealthData = false
    @State private var healthErrorMessage: String?
    @State private var lastSavedLog: TrainingLog?

    init(bundle: Bundle = .main, healthDataProvider: HealthDataProviding = MockHealthDataProvider()) {
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
        self.healthDataProvider = healthDataProvider
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
                Form {
                    dateSection
                    workoutSelectionSection(groups: groups)
                    strengthInputSection
                    cardioSection
                    healthSection
                    actionSection
                }
            }
        case .failure(let error):
            EmptyStateView(title: "メニューを読み込めませんでした", message: error.localizedDescription)
                .padding()
        }
    }

    private var dateSection: some View {
        Section("日付") {
            DatePicker("トレーニング日", selection: $selectedDate, displayedComponents: .date)
        }
    }

    private func workoutSelectionSection(groups: [WorkoutGroup]) -> some View {
        Section("種目選択") {
            let safeIndex = min(selectedGroupIndex, max(groups.count - 1, 0))
            Picker("部位", selection: $selectedGroupIndex) {
                ForEach(0..<groups.count, id: \.self) { index in
                    Text(groups[index].muscleGroup).tag(index)
                }
            }
            .pickerStyle(.segmented)

            ForEach(groups[safeIndex].menus, id: \.id) { item in
                Button(action: {
                    toggleSelection(for: item)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
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
        }
    }

    private var strengthInputSection: some View {
        Group {
            if !strengthInputs.isEmpty {
                Section("筋トレ入力") {
                    ForEach($strengthInputs) { $input in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(input.menuItem.name)
                                .font(.headline)
                            ForEach($input.sets) { $set in
                                HStack {
                                    TextField("重量 (kg)", text: $set.weightText)
                                        .keyboardType(.decimalPad)
                                    TextField("回数", text: $set.repetitionsText)
                                        .keyboardType(.numberPad)
                                }
                            }
                            Button(action: {
                                input.sets.append(StrengthSetInput())
                            }) {
                                Label("セットを追加", systemImage: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private var cardioSection: some View {
        Section("ランニング/有酸素") {
            TextField("距離 (km)", text: $cardioInput.distanceText)
                .keyboardType(.decimalPad)
            TextField("時間 (分:秒)", text: $cardioInput.durationText)
                .keyboardType(.numbersAndPunctuation)

            if let metrics = cardioInput.metrics {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ペース: \(metrics.formattedPace)")
                    Text(String(format: "距離: %.1f km", metrics.distanceInKilometers))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var healthSection: some View {
        Section("ヘルスケアデータ") {
            if let start = sessionStartDate {
                HStack {
                    Label("セッション開始", systemImage: "clock")
                    Spacer()
                    Text(start, style: .time)
                }
            } else {
                Text("記録開始後にHealthKitのデータを取得します。")
                    .foregroundColor(.secondary)
            }

            if isFetchingHealthData {
                ProgressView("ヘルスデータ取得中…")
            }

            if let healthErrorMessage {
                Text(healthErrorMessage)
                    .foregroundColor(.red)
            }

            if let snapshot = healthSnapshot {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(snapshot.availableMetrics.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                        HStack {
                            Text(item.key)
                            Spacer()
                            Text(item.value)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: startRecording) {
                Label("記録を開始", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedMenuItems.isEmpty)

            Button(action: saveLog) {
                Label("保存", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)

            if let lastSavedLog {
                VStack(alignment: .leading, spacing: 4) {
                    Text("保存済み: \(lastSavedLog.strengthExercises.count)種目")
                        .font(.subheadline)
                    if let cardio = lastSavedLog.cardio {
                        Text(String(format: "有酸素: %.1f km", cardio.distanceInKilometers))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let snapshot = lastSavedLog.healthSnapshot {
                        Text("ヘルスデータ: \(snapshot.availableMetrics.count)項目")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func toggleSelection(for item: WorkoutMenuItem) {
        if selectedMenuItems.contains(item) {
            selectedMenuItems.remove(item)
        } else {
            selectedMenuItems.insert(item)
        }
        syncStrengthInputs()
    }

    private func syncStrengthInputs() {
        strengthInputs = strengthInputs.filter { selectedMenuItems.contains($0.menuItem) }
        for menuItem in selectedMenuItems where !strengthInputs.contains(where: { $0.menuItem == menuItem }) {
            strengthInputs.append(StrengthExerciseInput(menuItem: menuItem))
        }
    }

    private func startRecording() {
        let startDate = Date()
        sessionStartDate = startDate
        healthSnapshot = nil
        healthErrorMessage = nil
        isFetchingHealthData = true

        Task {
            do {
                try await healthDataProvider.requestAuthorization()
                let snapshot = try await healthDataProvider.fetchSnapshot(since: startDate)
                await MainActor.run {
                    healthSnapshot = snapshot
                    isFetchingHealthData = false
                }
            } catch {
                await MainActor.run {
                    healthErrorMessage = error.localizedDescription
                    isFetchingHealthData = false
                }
            }
        }
    }

    private func saveLog() {
        let strengthLogs = strengthInputs.map { input in
            StrengthExerciseLog(
                name: input.menuItem.name,
                sets: input.sets.map { set in
                    StrengthSetLog(
                        weight: Double(set.weightText),
                        repetitions: Int(set.repetitionsText)
                    )
                }
            )
        }

        var cardioLog: CardioExerciseLog?
        if let metrics = cardioInput.metrics {
            cardioLog = CardioExerciseLog(
                distanceInKilometers: metrics.distanceInKilometers,
                durationInSeconds: metrics.durationInSeconds,
                pace: metrics.pacePerKilometer
            )
        }

        let log = TrainingLog(
            date: selectedDate,
            startedAt: sessionStartDate,
            strengthExercises: strengthLogs,
            cardio: cardioLog,
            healthSnapshot: healthSnapshot
        )
        lastSavedLog = log
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

private struct StrengthExerciseInput: Identifiable, Equatable {
    let id = UUID()
    var menuItem: WorkoutMenuItem
    var sets: [StrengthSetInput] = [StrengthSetInput()]
}

private struct StrengthSetInput: Identifiable, Equatable {
    let id = UUID()
    var weightText: String = ""
    var repetitionsText: String = ""
}

private struct CardioInput: Equatable {
    var distanceText: String = ""
    var durationText: String = ""

    var metrics: CardioMetrics? {
        guard let distance = Double(distanceText), distance > 0 else { return nil }
        guard let duration = Self.duration(from: durationText), duration > 0 else { return nil }
        return CardioMetrics(distanceInKilometers: distance, durationInSeconds: duration)
    }

    private static func duration(from text: String) -> TimeInterval? {
        let components = text.split(separator: ":")
        if components.count == 2,
           let minutes = Double(components[0]),
           let seconds = Double(components[1]) {
            return minutes * 60 + seconds
        }
        if let minutes = Double(text) {
            return minutes * 60
        }
        return nil
    }
}

#Preview {
    RecordingView()
}
