import SwiftUI

struct PlanDetailContentView: View {
    enum DisplayMode {
        case full
        case compact(maxItems: Int)
    }

    let content: PlanDisplayContent
    let mode: DisplayMode

    init(detail: String, mode: DisplayMode = .full) {
        self.content = PlanDisplayContent.parse(detail)
        self.mode = mode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.2) {
            switch mode {
            case .full:
                fullContent
            case .compact(let maxItems):
                compactContent(maxItems: maxItems)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var fullContent: some View {
        if !content.scheduleItems.isEmpty {
            PlanDetailSectionHeader(title: "週間メニュー", systemImage: "calendar")
            VStack(spacing: AppLayout.grid * 0.8) {
                ForEach(content.scheduleItems) { item in
                    PlanScheduleRow(item: item)
                }
            }
        }

        if !content.infoItems.isEmpty {
            PlanDetailSectionHeader(title: "調整ポイント", systemImage: "slider.horizontal.3")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppLayout.grid) {
                ForEach(content.infoItems) { item in
                    PlanInfoTile(item: item)
                }
            }
        }

        if !content.recoveryItems.isEmpty {
            PlanDetailSectionHeader(title: "回復・休養", systemImage: "leaf.fill")
            VStack(spacing: AppLayout.grid * 0.8) {
                ForEach(Array(content.recoveryItems.enumerated()), id: \.offset) { _, item in
                    PlanTextRow(systemImage: "checkmark.circle.fill", text: item)
                }
            }
        }

        if !content.notes.isEmpty {
            PlanDetailSectionHeader(title: "補足", systemImage: "text.alignleft")
            VStack(spacing: AppLayout.grid * 0.8) {
                ForEach(Array(content.notes.enumerated()), id: \.offset) { _, note in
                    PlanTextRow(systemImage: "circle.fill", text: note)
                }
            }
        }
    }

    @ViewBuilder
    private func compactContent(maxItems: Int) -> some View {
        let items = previewItems(limit: maxItems)
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: AppLayout.grid * 0.8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    PlanTextRow(systemImage: item.systemImage, text: item.text, compact: true)
                }
            }
        }
    }

    private func previewItems(limit: Int) -> [(systemImage: String, text: String)] {
        let schedule = content.scheduleItems.map { ("calendar", "\($0.day): \($0.detail)") }
        let info = content.infoItems.map { ("slider.horizontal.3", "\($0.title): \($0.value)") }
        let recovery = content.recoveryItems.map { ("leaf.fill", $0) }
        let notes = content.notes.map { ("text.alignleft", $0) }
        return Array((schedule + info + recovery + notes).prefix(limit))
    }
}

private struct PlanDetailSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: AppLayout.grid * 0.7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.primary)
                .frame(width: 18)
            Text(title)
                .font(AppTypography.label(13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.top, AppLayout.grid * 0.5)
    }
}

private struct PlanScheduleRow: View {
    let item: PlanScheduleItem

    var body: some View {
        HStack(alignment: .top, spacing: AppLayout.grid) {
            Text(item.day)
                .font(AppTypography.label(12, weight: .bold))
                .foregroundColor(AppColors.background)
                .frame(width: 34, height: 28)
                .background(Capsule().fill(AppColors.primary))

            Text(item.detail)
                .font(AppTypography.body(14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppLayout.grid * 0.8)
        .padding(.horizontal, AppLayout.grid)
        .background(AppColors.surface2.opacity(0.46))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }
}

private struct PlanInfoTile: View {
    let item: PlanInfoItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text(item.title)
                .font(AppTypography.label(11, weight: .semibold))
                .foregroundColor(AppColors.secondary)
            Text(item.value)
                .font(AppTypography.label(13, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.grid)
        .background(AppColors.surface2.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }
}

private struct PlanTextRow: View {
    let systemImage: String
    let text: String
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: AppLayout.grid * 0.8) {
            Image(systemName: systemImage)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
                .foregroundColor(AppColors.primary)
                .frame(width: 16, height: 18)
                .padding(.top, 1)
            Text(text)
                .font(AppTypography.label(compact ? 12 : 13, weight: compact ? .regular : .semibold))
                .foregroundColor(compact ? AppColors.textSecondary : AppColors.textPrimary)
                .lineLimit(compact ? 2 : nil)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PlanDetailContentView(
        detail: """
        * **Monday:** 胸・背中
        * **Wednesday:** 腕・肩
        * **Friday:** 下半身
        * **ボリューム:** 各セット3〜5回、各セット1〜3週間ごとに増やしていく。
        * **負荷:** 各セット1〜2週間ごとに増やしていく。
        * **休養:**
        * **Tuesday:** 軽いストレッチやウォーキング
        * **Saturday:** 完全休養
        * **Sunday:** 軽いストレッチやウォーキング
        """
    )
    .padding()
    .hudBackground()
}
