import Foundation

enum FetchError: Error, Equatable {
    case httpStatus(Int)
    case decode(Error)

    static func == (lhs: FetchError, rhs: FetchError) -> Bool {
        switch (lhs, rhs) {
        case (.httpStatus(let a), .httpStatus(let b)): a == b
        case (.decode, .decode): true
        default: false
        }
    }
}

struct UsageFetcher: Sendable {
    var session: URLSession = .shared
    var cloudBaseURL = URL(string: "https://ollama.com")!
    var localBaseURL = URL(string: "http://localhost:11434")!

    /// Quota windows (session + weekly percent remaining) — GET /api/balance
    func fetchBalance(apiKey: String) async throws -> BalanceResponse {
        try await fetchJSON(
            cloudBaseURL.appendingPathComponent("api/balance"),
            apiKey: apiKey,
            timeout: 10
        )
    }

    /// Usage history — GET /api/usage?range=7d
    func fetchUsageHistory(apiKey: String, range: String = "7d") async throws -> UsageResponse {
        var components = URLComponents(
            url: cloudBaseURL.appendingPathComponent("api/usage"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "range", value: range)]
        return try await fetchJSON(components.url!, apiKey: apiKey, timeout: 10)
    }

    /// Local model state — GET http://localhost:11434/api/ps
    func fetchLocalProcesses() async throws -> PsResponse {
        try await fetchJSON(
            localBaseURL.appendingPathComponent("api/ps"),
            apiKey: nil,
            timeout: 5
        )
    }

    private func fetchJSON<T: Decodable>(_ url: URL, apiKey: String?, timeout: TimeInterval) async throws -> T {
        var request = URLRequest(url: url)
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = timeout
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FetchError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw FetchError.decode(error) }
    }
}
