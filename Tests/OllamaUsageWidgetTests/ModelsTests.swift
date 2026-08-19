import Foundation
import Testing
@testable import OllamaUsageWidget

// NOTE: Uses Swift Testing (not XCTest) — this machine has no Xcode and the
// homebrew swift 6.3.3 toolchain ships Swift Testing only (no XCTest module).

struct ModelsTests {
    @Test func decodesCloudUsage() throws {
        let json = """
        {"activity":{"cost":"0.00000","period":{"type":"last_4_weeks","starting_at":"2026-07-27T00:00:00Z","ending_at":"2026-08-19T12:43:30.952965738Z"},"models":[]},"limits":{"session":{"usage":0.003,"models":[{"name":"deepseek-v4-flash:0731","request_count":32}]},"weekly":{"usage":0.213,"models":[{"name":"deepseek-v4-flash:0731","request_count":5046},{"name":"web search","request_count":7}]}}}
        """
        let decoded = try JSONDecoder().decode(UsageResponse.self, from: Data(json.utf8))
        #expect(decoded.limits.weekly.usage == 0.213)
        #expect(decoded.limits.weekly.models.count == 2)
        #expect(decoded.limits.weekly.models[0].name == "deepseek-v4-flash:0731")
        #expect(decoded.limits.weekly.models[0].requestCount == 5046)
        #expect(decoded.limits.session.usage == 0.003)
        #expect(decoded.activity.cost == "0.00000")
        #expect(decoded.activity.period.type == "last_4_weeks")
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
