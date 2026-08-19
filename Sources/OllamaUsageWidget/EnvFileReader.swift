import Foundation

enum EnvFileReader {
    static func ollamaKey() -> String? {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".hermes/.env")
        guard let contents = try? String(contentsOf: path, encoding: .utf8) else { return nil }
        return EnvParser.value(for: "OLLAMA_API_KEY", in: contents)
    }
}
