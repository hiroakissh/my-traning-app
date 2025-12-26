import SwiftUI

struct RecordingView: View {
    private struct Activity: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
    }

    private enum GoalType: String, CaseIterable, Identifiable {
        case time = "時間"
        case distance = "距離"
        case calorie = "カロリー"
        case heartRate = "心拍数"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .time: return "clock.fill"
            case .distance: return "location.fill"
            case .calorie: return "flame.fill"
            case .heartRate: return "heart.fill"
            }
        }
    }

    @State private var activities: [Activity] = [
        Activity(name: "ランニング", icon: "figure.run", color: AppColors.primary),
        Activity(name: "サイクリング", icon: "bicycle", color: Color.gray),
        Activity(name: "筋トレ", icon: "hammer.fill", color: AppColors.secondary)
    ]
    @State private var selectedActivityIndex: Int = 0

    @State private var selectedGoal: GoalType = .time
    @State private var goalValue: Double = 45 // minutes
    @State private var voiceCoachEnabled = true
    @State private var hapticsEnabled = true
    @State private var isRunning = false

    private var selectedActivity: Activity {
        activities[selectedActivityIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 2.5) {
                        header
                        activitySelector
                        goalSelector
                        timerRing
                        toggles
                        Spacer(minLength: AppLayout.grid * 6)
                    }
                    .padding(.horizontal, AppLayout.grid * 2.5)
                    .padding(.top, AppLayout.grid * 3)
                    .padding(.bottom, AppLayout.grid * 8)
                }

                startButton
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    // MARK: - Sections

    private var background: some View {
        LinearGradient(
            colors: [
                AppColors.background,
                AppColors.surface.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("ワークアウト設定")
                .font(AppTypography.title(20))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
    }

    private var activitySelector: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
            Text("種目を選択")
                .font(AppTypography.title(18))
                .foregroundColor(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.grid * 1.25) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        Button {
                            selectedActivityIndex = index
                        } label: {
                            HStack(spacing: AppLayout.grid) {
                                Image(systemName: activity.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(activity.name)
                                    .font(AppTypography.body(15, weight: .semibold))
                            }
                            .padding(.horizontal, AppLayout.grid * 2.5)
                            .padding(.vertical, AppLayout.grid * 1.4)
                            .frame(minWidth: 140)
                            .background(
                                Capsule()
                                    .fill(index == selectedActivityIndex ? AppColors.primary : AppColors.surface2.opacity(0.92))
                                    .overlay(
                                        Capsule()
                                            .stroke(AppColors.strokeGlow, lineWidth: 1)
                                    )
                                    .shadow(color: index == selectedActivityIndex ? AppColors.primary.opacity(0.3) : Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                            )
                            .foregroundColor(index == selectedActivityIndex ? AppColors.background : AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var goalSelector: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
            HStack {
                Text("目標設定")
                    .font(AppTypography.title(18))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button(action: {}) {
                    Text("編集")
                        .font(AppTypography.body(14, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }

            HStack(spacing: 0) {
                ForEach(GoalType.allCases) { type in
                    Button {
                        selectedGoal = type
                    } label: {
                        VStack(spacing: AppLayout.grid * 0.5) {
                            Image(systemName: type.symbol)
                            Text(type.rawValue)
                                .font(AppTypography.body(14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppLayout.grid * 1.4)
                        .foregroundColor(selectedGoal == type ? AppColors.background : AppColors.textSecondary)
                        .background(
                            Capsule()
                                .fill(selectedGoal == type ? AppColors.primary : AppColors.surface.opacity(0.8))
                        )
                    }
                }
            }
            .padding(6)
            .background(
                Capsule()
                    .fill(AppColors.surface.opacity(0.7))
                    .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
            )
        }
    }

    private var timerRing: some View {
        VStack(spacing: AppLayout.grid * 1.5) {
            ZStack {
                Circle()
                    .stroke(AppColors.surface2.opacity(0.6), lineWidth: 18)
                    .frame(width: 260, height: 260)
                Circle()
                    .trim(from: 0, to: min(goalProgress, 1))
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 260, height: 260)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 16, x: 0, y: 10)

                VStack(spacing: AppLayout.grid * 0.8) {
                    Text(formattedGoal)
                        .font(AppTypography.hudNumber(44, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(selectedGoal.rawValue)
                        .font(AppTypography.body(15, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }

            Slider(value: $goalValue, in: goalRange.lowerBound...goalRange.upperBound, step: goalStep)
                .tint(AppColors.primary)
                .padding(.horizontal, AppLayout.grid * 2)
        }
        .padding(.vertical, AppLayout.grid * 2)
    }

    private var toggles: some View {
        VStack(spacing: AppLayout.grid * 1.5) {
            ToggleCard(
                icon: "person.wave.2.fill",
                title: "音声コーチ",
                subtitle: "区間ごとの音声ガイド",
                isOn: $voiceCoachEnabled
            )
            ToggleCard(
                icon: "wave.3.right",
                title: "ハプティック",
                subtitle: "アラート時の振動",
                isOn: $hapticsEnabled
            )
        }
    }

    private var startButton: some View {
        Button {
            isRunning.toggle()
        } label: {
            HStack(spacing: AppLayout.grid * 1.5) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                Text(isRunning ? "一時停止" : "スタート")
                    .font(AppTypography.body(18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppLayout.grid * 2)
            .background(
                Capsule()
                    .fill(AppColors.primary)
                    .shadow(color: AppColors.primary.opacity(0.4), radius: 18, x: 0, y: 10)
            )
            .foregroundColor(AppColors.background)
            .padding(.horizontal, AppLayout.grid * 2.5)
            .padding(.bottom, AppLayout.grid * 2.5)
        }
    }

    // MARK: - Helpers

    private var goalProgress: Double {
        switch selectedGoal {
        case .time:
            return goalValue / 120 // assume max 120 minutes
        case .distance:
            return goalValue / 20
        case .calorie:
            return goalValue / 1200
        case .heartRate:
            return goalValue / 200
        }
    }

    private var goalRange: ClosedRange<Double> {
        switch selectedGoal {
        case .time: return 10...120
        case .distance: return 1...30
        case .calorie: return 100...1200
        case .heartRate: return 80...200
        }
    }

    private var goalStep: Double {
        switch selectedGoal {
        case .time: return 5
        case .distance: return 0.5
        case .calorie: return 50
        case .heartRate: return 5
        }
    }

    private var formattedGoal: String {
        switch selectedGoal {
        case .time:
            let minutes = Int(goalValue)
            let seconds = Int((goalValue - Double(minutes)) * 60)
            return String(format: "%02d:%02d", minutes, seconds)
        case .distance:
            return String(format: "%.1f km", goalValue)
        case .calorie:
            return "\(Int(goalValue)) kcal"
        case .heartRate:
            return "\(Int(goalValue)) bpm"
        }
    }
}

// MARK: - Components

private struct ToggleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppLayout.grid * 1.25) {
            ZStack {
                Circle()
                    .fill(AppColors.surface2.opacity(0.9))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
                Text(title)
                    .font(AppTypography.body(15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppTypography.label(12))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        .padding(.horizontal, AppLayout.grid * 1.75)
        .padding(.vertical, AppLayout.grid * 1.35)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .fill(AppColors.surface.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous).stroke(AppColors.strokeGlow, lineWidth: 1))
                .shadow(color: AppColors.primary.opacity(0.16), radius: 14, x: 0, y: 10)
        )
    }
}

#Preview {
    RecordingView()
}
