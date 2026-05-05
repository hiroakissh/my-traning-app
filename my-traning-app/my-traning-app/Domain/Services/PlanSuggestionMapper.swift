import Foundation

enum PlanSuggestionMapper {
    static func map(from response: String, prompt: String, date: Date = Date()) -> [PlanSuggestion] {
        // 1. JSON形式 (推奨) を優先してパース
        if let jsonSuggestions = decodeJSONSuggestions(from: response, prompt: prompt, date: date), jsonSuggestions.isEmpty == false {
            return jsonSuggestions
        }

        // 2. Markdown風セクションのフォールバック
        let sections = splitIntoSections(from: response)
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSections = sections.isEmpty ? [("プラン", trimmedResponse.isEmpty ? [] : [trimmedResponse])] : sections

        return normalizedSections.enumerated().map { index, section in
            let title = section.0.isEmpty ? "プラン" : section.0
            let detail = section.1.isEmpty ? (trimmedResponse.isEmpty ? "提案が見つかりませんでした。" : trimmedResponse) : section.1.joined(separator: "\n")
            let summary = section.1.first ?? title

            return PlanSuggestion(
                id: UUID(),
                horizon: PlanHorizon.fromTitle(title),
                title: title,
                summary: summary,
                detail: detail,
                rawText: response,
                sourcePrompt: prompt,
                createdAt: date.addingTimeInterval(TimeInterval(index))
            )
        }
    }

    private static func splitIntoSections(from response: String) -> [(String, [String])] {
        let lines = response.components(separatedBy: .newlines)
        var sections: [(String, [String])] = []
        var currentTitle: String?
        var currentBody: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                let headingLevel = trimmed.prefix { $0 == "#" }.count
                guard headingLevel >= 3 else { continue }

                if let title = currentTitle {
                    sections.append((title, currentBody))
                } else if !currentBody.isEmpty {
                    sections.append(("プラン", currentBody))
                }
                currentTitle = trimmed.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                currentBody = []
            } else if !trimmed.isEmpty {
                currentBody.append(trimmed)
            }
        }

        if let title = currentTitle {
            sections.append((title, currentBody))
        } else if !currentBody.isEmpty {
            sections.append(("プラン", currentBody))
        }

        return sections
    }

    // MARK: - JSON parser (推奨形式)

    private struct PlanSuggestionPayload: Decodable {
        let title: String
        let summary: String?
        let detail: String?
        let horizon: String?
    }

    private struct PlanSuggestionsEnvelope: Decodable {
        let plans: [PlanSuggestionPayload]
    }

    private static func decodeJSONSuggestions(from response: String, prompt: String, date: Date) -> [PlanSuggestion]? {
        let data = Data(response.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // パターン1: 配列ルート
        if let payloads = try? decoder.decode([PlanSuggestionPayload].self, from: data) {
            return mapPayloads(payloads, prompt: prompt, date: date, raw: response)
        }
        // パターン2: { "plans": [...] }
        if let envelope = try? decoder.decode(PlanSuggestionsEnvelope.self, from: data) {
            return mapPayloads(envelope.plans, prompt: prompt, date: date, raw: response)
        }

        return nil
    }

    private static func mapPayloads(_ payloads: [PlanSuggestionPayload], prompt: String, date: Date, raw: String) -> [PlanSuggestion] {
        payloads.enumerated().map { index, item in
            let title = item.title.isEmpty ? "プラン" : item.title
            let horizon = PlanHorizon(rawValue: item.horizon ?? "") ?? PlanHorizon.fromTitle(title)
            let detailText = item.detail ?? item.summary ?? title

            return PlanSuggestion(
                id: UUID(),
                horizon: horizon,
                title: title,
                summary: item.summary ?? title,
                detail: detailText,
                rawText: raw,
                sourcePrompt: prompt,
                createdAt: date.addingTimeInterval(TimeInterval(index))
            )
        }
    }
}
