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
            return "長期プラン"
        case .midTerm:
            return "中期プラン"
        case .shortTerm:
            return "短期プラン"
        case .general:
            return "プラン"
        }
    }

    static func fromTitle(_ title: String) -> PlanHorizon {
        if title.contains("長期") {
            return .longTerm
        }
        if title.contains("中期") {
            return .midTerm
        }
        if title.contains("短期") {
            return .shortTerm
        }
        return .general
    }
}

struct PlanSuggestion: Identifiable, Equatable {
    let id: UUID
    let horizon: PlanHorizon
    let title: String
    let summary: String
    let detail: String
    let rawText: String
    let sourcePrompt: String
    let createdAt: Date
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
