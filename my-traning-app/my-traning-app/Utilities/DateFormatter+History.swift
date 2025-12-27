import Foundation

extension DateFormatter {
    static let historyDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd (E)"
        return formatter
    }()
}
