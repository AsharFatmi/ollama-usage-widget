import Testing
@testable import OllamaUsageWidget

struct EnvParserTests {
    @Test func extractsValue() {
        let env = "# comment\nOLLAMA_API_KEY=abc123\nOTHER=x\n"
        #expect(EnvParser.value(for: "OLLAMA_API_KEY", in: env) == "abc123")
    }

    @Test func ignoresCommentedKey() {
        let env = "# OLLAMA_API_KEY=commented\nOLLAMA_API_KEY=real\n"
        #expect(EnvParser.value(for: "OLLAMA_API_KEY", in: env) == "real")
    }

    @Test func missingKeyReturnsNil() {
        #expect(EnvParser.value(for: "NOPE", in: "A=1\nB=2\n") == nil)
    }

    @Test func trimsWhitespace() {
        #expect(EnvParser.value(for: "K", in: "K = spaced \n") == "spaced")
    }
}
