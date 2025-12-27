import Foundation

extension ExerciseCategory {
    var displayName: String {
        switch self {
        case .strength: return "筋トレ"
        case .cardio: return "有酸素"
        case .mobility: return "モビリティ"
        case .other: return "その他"
        }
    }
}

struct TrainingHistoryItem: Identifiable, Equatable {
    let id: UUID
    let log: TrainingLog
    let date: Date
    let dateLabel: String
    let title: String
    let subtitle: String
    let categories: Set<ExerciseCategory>
    let bodyParts: Set<BodyPart>
    let totalSets: Int
    let searchableText: String

    static func == (lhs: TrainingHistoryItem, rhs: TrainingHistoryItem) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.categories == rhs.categories
            && lhs.bodyParts == rhs.bodyParts
            && lhs.totalSets == rhs.totalSets
            && lhs.searchableText == rhs.searchableText
    }
}

enum TrainingHistoryBuilder {

    static func makeItems(
        from logs: [TrainingLog],
        calendar: Calendar = .current,
        dateFormatter: DateFormatter = .historyDisplay
    ) -> [TrainingHistoryItem] {
        logs.map { log in
            let categories = Set(log.exercises.map(\.category))
            let bodyParts = Set(log.exercises.map(\.bodyPart))
            let exerciseNames = log.exercises.map(\.name).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let totalSets = log.exercises.flatMap(\.sets).count

            let title = exerciseNames.first ?? "トレーニング"
            let bodyPartText = bodyParts.isEmpty ? nil : bodyParts.map(\.displayName).sorted().joined(separator: "・")

            let subtitleComponents: [String?] = [
                log.purpose.displayName,
                totalSets > 0 ? "\(totalSets)セット" : nil,
                bodyPartText
            ]
            let subtitle = subtitleComponents.compactMap { $0 }.joined(separator: " ・ ")

            let searchableParts = exerciseNames
                + [log.note, log.purpose.displayName, bodyPartText]
            let searchableText = searchableParts
                .compactMap { $0 }
                .joined(separator: " ")

            return TrainingHistoryItem(
                id: log.id,
                log: log,
                date: log.date,
                dateLabel: dateFormatter.string(from: log.date),
                title: title,
                subtitle: subtitle,
                categories: categories.isEmpty ? Set([.other]) : categories,
                bodyParts: bodyParts.isEmpty ? Set([.other]) : bodyParts,
                totalSets: totalSets,
                searchableText: searchableText
            )
        }
    }
}

enum TrainingHistoryFilter {
    static func apply(
        items: [TrainingHistoryItem],
        searchText: String,
        category: ExerciseCategory?,
        date: Date?,
        calendar: Calendar = .current
    ) -> [TrainingHistoryItem] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            if let category, !item.categories.contains(category) {
                return false
            }

            if let date, !calendar.isDate(item.date, inSameDayAs: date) {
                return false
            }

            if !normalizedSearch.isEmpty && !item.searchableText.lowercased().contains(normalizedSearch) {
                return false
            }

            return true
        }
    }
}
