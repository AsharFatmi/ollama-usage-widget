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
    @Test func balanceSuccessSendsBearerHeaderAndDecodes() async throws {
        let expectedKey = "test-api-key-123"
        var capturedAuth: String?
        var capturedTimeout: TimeInterval?
        var capturedPath: String?
        MockURLProtocol.handler = { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
            capturedTimeout = request.timeoutInterval
            capturedPath = request.url?.path
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = """
            {"included":{"session":{"remaining_percent":84.58,"resets_at":"2026-10-14T05:00:00Z"},"weekly":{"remaining_percent":95.93,"resets_at":"2026-10-19T00:00:00Z"}},"purchased":{"balance_usd":0}}
            """
            return (response, Data(json.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let fetcher = UsageFetcher(session: makeMockSession())
        let balance = try await fetcher.fetchBalance(apiKey: expectedKey)

        #expect(capturedAuth == "Bearer \(expectedKey)")
        #expect(capturedTimeout == 10)
        #expect(capturedPath == "/api/balance")
        #expect(balance.included.weekly?.remainingPercent == 95.93)
    }

    @Test func usageHistoryRequestsSevenDayRange() async throws {
        var capturedQuery: String?
        MockURLProtocol.handler = { request in
            capturedQuery = request.url?.query
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let json = """
            {"range":"7d","granularity":"day","from":"2026-10-07T00:00:00Z","until":"2026-10-14T01:00:00Z","totals":{"request_count":447},"buckets":[{"from":"2026-10-07T00:00:00Z","until":"2026-10-08T00:00:00Z","request_count":0},{"from":"2026-10-08T00:00:00Z","until":"2026-10-09T00:00:00Z","request_count":19}]}
            """
            return (response, Data(json.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let fetcher = UsageFetcher(session: makeMockSession())
        let usage = try await fetcher.fetchUsageHistory(apiKey: "test-key")

        #expect(capturedQuery == "range=7d")
        #expect(usage.totals.requestCount == 447)
        #expect(usage.buckets.count == 2)
    }

    @Test func balance401ThrowsHttpStatus() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        defer { MockURLProtocol.handler = nil }

        let fetcher = UsageFetcher(session: makeMockSession())
        await #expect(throws: FetchError.httpStatus(401)) {
            _ = try await fetcher.fetchBalance(apiKey: "bad-key")
        }
    }

    @Test func localSuccessDecodesPsResponse() async throws {
        var capturedTimeout: TimeInterval?
        var capturedAuth: String?
        MockURLProtocol.handler = { request in
            capturedTimeout = request.timeoutInterval
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
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
        #expect(capturedAuth == nil) // local endpoint carries no auth header
        #expect(ps.models.count == 1)
        #expect(ps.models[0].name == "llama3.2:3b")
        #expect(ps.models[0].sizeVram == 2019553184)
    }
}
