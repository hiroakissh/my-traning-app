import Foundation
import SwiftData

enum PlanHorizon: String, Codable, CaseIterable {
    case longTerm
    case midTerm
    case shortTerm
    case general

    var displayName: String {
        switch self {
        case .longTerm:
            return "目標"
        case .midTerm:
            return "今のフェーズ"
        case .shortTerm:
            return "今週の作戦"
        case .general:
            return "今日やること"
        }
    }

    static func fromTitle(_ title: String) -> PlanHorizon {
        if title.contains("長期") || title.localizedCaseInsensitiveContains("goal") || title.contains("目標") {
            return .longTerm
        }
        if title.contains("中期") || title.localizedCaseInsensitiveContains("phase") || title.contains("フェーズ") {
            return .midTerm
        }
        if title.contains("短期") || title.localizedCaseInsensitiveContains("week") || title.contains("今週") {
            return .shortTerm
        }
        return .general
    }
}

struct PlanSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    let horizon: PlanHorizon
    let title: String
    let summary: String
    let detail: String
    let rawText: String
    let sourcePrompt: String
    let createdAt: Date
}

struct PlanSuggestionOutput: Codable, Equatable {
    let title: String
    let summary: String
    let horizon: String
    let detail: String
}

struct PlanSuggestionsOutput: Codable, Equatable {
    let plans: [PlanSuggestionOutput]

    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
}

@Model
final class ActivePlan {
    @Attribute(.unique) var id: UUID
    var horizonRaw: String
    var title: String
    var summary: String
    var detail: String
    var sourcePrompt: String
    var adoptedAt: Date

    var horizon: PlanHorizon {
        get { PlanHorizon(rawValue: horizonRaw) ?? .general }
        set { horizonRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        horizon: PlanHorizon,
        title: String,
        summary: String,
        detail: String,
        sourcePrompt: String,
        adoptedAt: Date = Date()
    ) {
        self.id = id
        self.horizonRaw = horizon.rawValue
        self.title = title
        self.summary = summary
        self.detail = detail
        self.sourcePrompt = sourcePrompt
        self.adoptedAt = adoptedAt
    }
}
