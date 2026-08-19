import Foundation
import Testing
@testable import OllamaUsageWidget

// NOTE: Uses Swift Testing (not XCTest) — this machine has no Xcode and the
// homebrew swift 6.3.3 toolchain ships Swift Testing only (no XCTest module).

/// URLProtocol stub that answers every request from a static handler closure.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

// Tests share the static MockURLProtocol.handler, so they must not run in parallel.
@Suite(.serialized)
struct UsageFetcherTests {
    @Test func cloudSuccessSendsBearerHeaderAndDecodes() async throws {
        let expectedKey = "test-api-key-123"
        var capturedAuth: String?
        var capturedTimeout: TimeInterval?
        MockURLProtocol.handler = { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
            capturedTimeout = request.timeoutInterval
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = """
            {"activity":{"cost":"0.00000","period":{"type":"last_4_weeks","starting_at":"2026-07-27T00:00:00Z","ending_at":"2026-08-19T12:43:30Z"},"models":[]},"limits":{"session":{"usage":0.003,"models":[]},"weekly":{"usage":0.213,"models":[{"name":"deepseek-v4-flash:0731","request_count":5046}]}}}
            """
            return (response, Data(json.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let fetcher = UsageFetcher(session: makeMockSession())
        let usage = try await fetcher.fetchCloudUsage(apiKey: expectedKey)

        #expect(capturedAuth == "Bearer \(expectedKey)")
        #expect(capturedTimeout == 10)
        #expect(usage.limits.weekly.usage == 0.213)
        #expect(usage.limits.weekly.models[0].requestCount == 5046)
    }

    @Test func cloud401ThrowsHttpStatus() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        defer { MockURLProtocol.handler = nil }

        let fetcher = UsageFetcher(session: makeMockSession())
        await #expect(throws: FetchError.httpStatus(401)) {
            _ = try await fetcher.fetchCloudUsage(apiKey: "k")
        }
    }

    @Test func localSuccessDecodesPsResponse() async throws {
        var capturedTimeout: TimeInterval?
        MockURLProtocol.handler = { request in
            capturedTimeout = request.timeoutInterval
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = """
            {"models":[{"name":"llama3.2:3b","size":2019553184,"size_vram":2019553184,"expires_at":"2026-08-19T06:00:00Z"}]}
            """
            return (response, Data(json.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let fetcher = UsageFetcher(session: makeMockSession())
        let ps = try await fetcher.fetchLocalProcesses()

        #expect(capturedTimeout == 5)
        #expect(ps.models.count == 1)
        #expect(ps.models[0].name == "llama3.2:3b")
        #expect(ps.models[0].sizeVram == 2019553184)
    }
}
