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

    func fetchCloudUsage(apiKey: String) async throws -> UsageResponse {
        let url = cloudBaseURL.appendingPathComponent("api/usage")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FetchError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do { return try JSONDecoder().decode(UsageResponse.self, from: data) }
        catch { throw FetchError.decode(error) }
    }

    func fetchLocalProcesses() async throws -> PsResponse {
        let url = localBaseURL.appendingPathComponent("api/ps")
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FetchError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        do { return try JSONDecoder().decode(PsResponse.self, from: data) }
        catch { throw FetchError.decode(error) }
    }
}
