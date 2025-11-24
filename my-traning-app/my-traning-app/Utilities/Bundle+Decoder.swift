import Foundation

enum BundleDecodingError: Error, LocalizedError, Equatable {
    case fileNotFound(file: String)
    case dataReadFailed(file: String, reason: String)
    case decodingFailed(file: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let file):
            return "バンドル内に\(file)が見つかりませんでした。"
        case .dataReadFailed(let file, let reason):
            return "\(file)の読み込みに失敗しました: \(reason)"
        case .decodingFailed(let file, let reason):
            return "\(file)のデコードに失敗しました: \(reason)"
        }
    }
}

extension Bundle {
    func decode<T: Decodable>(_ file: String) throws -> T {
        let components = (file as NSString)
        let resource = components.deletingPathExtension
        let pathExtension = components.pathExtension.isEmpty ? nil : components.pathExtension

        guard let url = self.url(forResource: resource, withExtension: pathExtension) else {
            throw BundleDecodingError.fileNotFound(file: file)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BundleDecodingError.dataReadFailed(file: file, reason: error.localizedDescription)
        }

        return try Bundle.decode(T.self, from: data, fileName: file)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data, fileName: String) throws -> T {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BundleDecodingError.decodingFailed(file: fileName, reason: error.localizedDescription)
        }
    }
}
