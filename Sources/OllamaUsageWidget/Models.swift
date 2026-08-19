import Foundation

// MARK: - Cloud usage (GET https://ollama.com/api/usage)

struct UsageResponse: Codable, Sendable {
    let activity: Activity
    let limits: Limits
}

struct Activity: Codable, Sendable {
    let cost: String
    let period: Period
    let models: [ModelUsage]
}

struct Period: Codable, Sendable {
    let type: String
    let startingAt: String
    let endingAt: String

    enum CodingKeys: String, CodingKey {
        case type
        case startingAt = "starting_at"
        case endingAt = "ending_at"
    }
}

struct Limits: Codable, Sendable {
    let session: LimitBucket
    let weekly: LimitBucket
}

struct LimitBucket: Codable, Sendable {
    let usage: Double
    let models: [ModelUsage]
}

struct ModelUsage: Codable, Sendable {
    let name: String
    let requestCount: Int

    enum CodingKeys: String, CodingKey {
        case name
        case requestCount = "request_count"
    }
}

// MARK: - Local processes (GET http://localhost:11434/api/ps)

struct PsResponse: Codable, Sendable {
    let models: [PsModel]
}

struct PsModel: Codable, Sendable {
    let name: String
    let size: Int64
    let sizeVram: Int64
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case name, size
        case sizeVram = "size_vram"
        case expiresAt = "expires_at"
    }
}
