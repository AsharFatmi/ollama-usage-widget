import Foundation
import Testing
@testable import OllamaUsageWidget

// NOTE: Uses Swift Testing (not XCTest) — this machine has no Xcode and the
// homebrew swift 6.3.3 toolchain ships Swift Testing only (no XCTest module).

struct ModelsTests {
    @Test func decodesBalance() throws {
        let json = """
        {"included":{"session":{"remaining_percent":84.58,"resets_at":"2026-10-14T05:00:00Z"},"weekly":{"remaining_percent":95.93,"resets_at":"2026-10-19T00:00:00Z"}},"purchased":{"balance_usd":0}}
        """
        let decoded = try JSONDecoder().decode(BalanceResponse.self, from: Data(json.utf8))
        #expect(decoded.included.session?.remainingPercent == 84.58)
        #expect(decoded.included.weekly?.remainingPercent == 95.93)
        #expect(decoded.included.weekly?.resetsAt == "2026-10-19T00:00:00Z")
        #expect(decoded.purchased?.balanceUSD == 0)
        // usedFraction = (100 - remaining) / 100, clamped to 0…1
        #expect(abs((decoded.included.session?.usedFraction ?? -1) - 0.1542) < 0.0001)
        #expect(abs((decoded.included.weekly?.usedFraction ?? -1) - 0.0407) < 0.0001)
    }

    @Test func decodesUsageHistory() throws {
        let json = """
        {"range":"7d","scope":"self","granularity":"day","from":"2026-10-07T00:00:00Z","until":"2026-10-14T01:21:37Z","totals":{"request_count":447},"buckets":[{"from":"2026-10-07T00:00:00Z","until":"2026-10-08T00:00:00Z","request_count":0},{"from":"2026-10-13T00:00:00Z","until":"2026-10-14T00:00:00Z","request_count":55},{"from":"2026-10-14T00:00:00Z","until":"2026-10-14T01:21:37Z","partial":true,"request_count":325}]}
        """
        let decoded = try JSONDecoder().decode(UsageResponse.self, from: Data(json.utf8))
        #expect(decoded.range == "7d")
        #expect(decoded.totals.requestCount == 447)
        #expect(decoded.buckets.count == 3)
        #expect(decoded.buckets[1].requestCount == 55)
        #expect(decoded.buckets[2].partial == true)
    }

    @Test func decodesLocalProcesses() throws {
        let json = """
        {"models":[{"name":"llama3.2:3b","model":"llama3.2:3b","size":2019553184,"details":{"parent_model":"","format":"gguf","family":"llama","families":["llama"],"parameter_size":"3.2B","quantization_level":"Q4_K_M"},"expires_at":"2026-08-19T06:00:00Z","size_vram":2019553184}]}
        """
        let decoded = try JSONDecoder().decode(PsResponse.self, from: Data(json.utf8))
        #expect(decoded.models.count == 1)
        #expect(decoded.models[0].name == "llama3.2:3b")
        #expect(decoded.models[0].sizeVram == 2019553184)
    }
}
