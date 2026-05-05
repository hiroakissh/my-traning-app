import Foundation

struct PlanDisplayContent: Equatable {
    var scheduleItems: [PlanScheduleItem]
    var infoItems: [PlanInfoItem]
    var recoveryItems: [String]
    var notes: [String]

    var isEmpty: Bool {
        scheduleItems.isEmpty && infoItems.isEmpty && recoveryItems.isEmpty && notes.isEmpty
    }

    static func parse(_ text: String) -> PlanDisplayContent {
        PlanDisplayContentParser.parse(text)
    }
}

struct PlanScheduleItem: Identifiable, Equatable {
    let id: String
    let day: String
    let detail: String
}

struct PlanInfoItem: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
}

private enum PlanDisplaySection {
    case general
    case recovery
}

private enum PlanDisplayContentParser {
    static func parse(_ text: String) -> PlanDisplayContent {
        let lines = text
            .components(separatedBy: .newlines)
            .map(cleanLine)
            .filter { !$0.isEmpty }

        var scheduleItems: [PlanScheduleItem] = []
        var infoItems: [PlanInfoItem] = []
        var recoveryItems: [String] = []
        var notes: [String] = []
        var section: PlanDisplaySection = .general
        var seenLines = Set<String>()

        for line in lines {
            let normalizedLine = normalizeForDedup(line)
            guard !seenLines.contains(normalizedLine) else { continue }
            seenLines.insert(normalizedLine)

            let keyValue = splitKeyValue(line)
            let key = keyValue?.key ?? line
            let value = keyValue?.value ?? ""

            if isRecoveryHeader(key) {
                section = .recovery
                if !value.isEmpty {
                    appendUnique("\(localizedRecoveryTitle(for: key)): \(value)", to: &recoveryItems)
                }
                continue
            }

            if let day = localizedDay(for: key), !value.isEmpty {
                if section == .recovery {
                    appendUnique("\(day): \(value)", to: &recoveryItems)
                } else {
                    scheduleItems.append(
                        PlanScheduleItem(
                            id: makeId(prefix: "schedule", index: scheduleItems.count, title: day, value: value),
                            day: day,
                            detail: value
                        )
                    )
                }
                continue
            }

            if let title = localizedInfoTitle(for: key), !value.isEmpty {
                section = .general
                infoItems.append(
                    PlanInfoItem(
                        id: makeId(prefix: "info", index: infoItems.count, title: title, value: value),
                        title: title,
                        value: value
                    )
                )
                continue
            }

            switch section {
            case .general:
                notes.append(line)
            case .recovery:
                appendUnique(line, to: &recoveryItems)
            }
        }

        if scheduleItems.isEmpty && infoItems.isEmpty && recoveryItems.isEmpty && notes.isEmpty {
            let fallback = cleanLine(text)
            if !fallback.isEmpty {
                notes = [fallback]
            }
        }

        return PlanDisplayContent(
            scheduleItems: scheduleItems,
            infoItems: infoItems,
            recoveryItems: recoveryItems,
            notes: notes
        )
    }

    private static func cleanLine(_ rawLine: String) -> String {
        var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        line = line.replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
        line = line.replacingOccurrences(of: "^[-*•]+\\s*", with: "", options: .regularExpression)
        line = line.replacingOccurrences(of: "**", with: "")
        line = line.replacingOccurrences(of: "__", with: "")
        line = line.replacingOccurrences(of: "`", with: "")
        line = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return line.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func splitKeyValue(_ line: String) -> (key: String, value: String)? {
        guard let separator = line.firstIndex(where: { $0 == ":" || $0 == "：" }) else {
            return nil
        }

        let key = String(line[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
        let valueStart = line.index(after: separator)
        let value = String(line[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        return (key, value)
    }

    private static func localizedDay(for key: String) -> String? {
        let normalized = normalizeKey(key)
        let mappings: [(String, String)] = [
            ("monday", "月"), ("mon", "月"), ("月曜日", "月"), ("月曜", "月"), ("月", "月"),
            ("tuesday", "火"), ("tue", "火"), ("火曜日", "火"), ("火曜", "火"), ("火", "火"),
            ("wednesday", "水"), ("wed", "水"), ("水曜日", "水"), ("水曜", "水"), ("水", "水"),
            ("thursday", "木"), ("thu", "木"), ("木曜日", "木"), ("木曜", "木"), ("木", "木"),
            ("friday", "金"), ("fri", "金"), ("金曜日", "金"), ("金曜", "金"), ("金", "金"),
            ("saturday", "土"), ("sat", "土"), ("土曜日", "土"), ("土曜", "土"), ("土", "土"),
            ("sunday", "日"), ("sun", "日"), ("日曜日", "日"), ("日曜", "日"), ("日", "日"),
            ("weekend", "週末"), ("土日", "週末"), ("週末", "週末")
        ]
        return mappings.first { normalized == normalizeKey($0.0) }?.1
    }

    private static func localizedInfoTitle(for key: String) -> String? {
        let normalized = normalizeKey(key)
        let mappings: [(String, String)] = [
            ("goal", "目標"), ("目標", "目標"),
            ("focus", "重点"), ("フォーカス", "重点"), ("重点", "重点"),
            ("phase", "方針"), ("方針", "方針"),
            ("content", "内容"), ("内容", "内容"),
            ("frequency", "頻度"), ("頻度", "頻度"),
            ("volume", "ボリューム"), ("ボリューム", "ボリューム"),
            ("load", "負荷"), ("負荷", "負荷"),
            ("intensity", "強度"), ("強度", "強度"),
            ("duration", "期間"), ("期間", "期間")
        ]
        return mappings.first { normalized == normalizeKey($0.0) }?.1
    }

    private static func isRecoveryHeader(_ key: String) -> Bool {
        let normalized = normalizeKey(key)
        let headers = [
            "rest", "休養", "休息", "回復", "recovery", "recoveryadvice",
            "recovery advice", "筋肉痛", "睡眠", "疲労"
        ]
        return headers.contains { normalized == normalizeKey($0) }
    }

    private static func localizedRecoveryTitle(for key: String) -> String {
        let normalized = normalizeKey(key)
        if normalized.contains("筋肉痛") { return "筋肉痛" }
        if normalized.contains("睡眠") { return "睡眠" }
        if normalized.contains("疲労") { return "疲労" }
        if normalized.contains("rest") || normalized.contains("休養") || normalized.contains("休息") {
            return "休養"
        }
        return "回復"
    }

    private static func normalizeKey(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "・", with: "")
    }

    private static func normalizeForDedup(_ value: String) -> String {
        normalizeKey(value.replacingOccurrences(of: "：", with: ":"))
    }

    private static func appendUnique(_ value: String, to values: inout [String]) {
        let normalized = normalizeForDedup(value)
        guard values.contains(where: { normalizeForDedup($0) == normalized }) == false else { return }
        values.append(value)
    }

    private static func makeId(prefix: String, index: Int, title: String, value: String) -> String {
        "\(prefix)-\(index)-\(title)-\(value)".replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
    }
}
