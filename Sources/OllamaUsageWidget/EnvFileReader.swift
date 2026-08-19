import Foundation

enum EnvFileReader {
    /// Standard locations checked for OLLAMA_API_KEY (in order):
    /// 1. ~/.ollama-usage-widget/.env
    /// 2. ~/.config/ollama-usage-widget/.env
    /// 3. ~/.ollama-usage-widget.env
    /// 4. ~/.hermes/.env (Hermes-agent environments, kept for existing setups)
    static func ollamaKey() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            home.appendingPathComponent(".ollama-usage-widget/.env"),
            home.appendingPathComponent(".config/ollama-usage-widget/.env"),
            home.appendingPathComponent(".ollama-usage-widget.env"),
            home.appendingPathComponent(".hermes/.env"),
        ]
        for path in candidates {
            if let contents = try? String(contentsOf: path, encoding: .utf8),
               let key = EnvParser.value(for: "OLLAMA_API_KEY", in: contents) {
                return key
            }
        }
        return nil
    }
}
