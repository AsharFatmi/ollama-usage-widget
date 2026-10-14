import Foundation

// MARK: - Cloud balance (GET https://ollama.com/api/balance)
//
// Documented endpoint (see Ollama's cloud API docs). Legacy plans (session +
// weekly limits) return percent-remaining windows with reset times; newer
// plans return dollar balances instead.

struct BalanceResponse: Codable, Sendable {
    let included: Included
    let purchased: Purchased?

    struct Included: Codable, Sendable {
        let session: Window?
        let weekly: Window?
        let balanceUSD: Double?
        let allowanceUSD: Double?

        enum CodingKeys: String, CodingKey {
            case session, weekly
            case balanceUSD = "balance_usd"
            case allowanceUSD = "allowance_usd"
        }
    }

    struct Window: Codable, Sendable {
        let remainingPercent: Double
        let resetsAt: String

        enum CodingKeys: String, CodingKey {
            case remainingPercent = "remaining_percent"
            case resetsAt = "resets_at"
        }

        /// Fraction of the window's quota already used (0…1).
        var usedFraction: Double { max(0, min(1, (100 - remainingPercent) / 100)) }
    }

    struct Purchased: Codable, Sendable {
        let balanceUSD: Double

        enum CodingKeys: String, CodingKey {
            case balanceUSD = "balance_usd"
        }
    }
}

// MARK: - Cloud usage history (GET https://ollama.com/api/usage?range=7d)

struct UsageResponse: Codable, Sendable {
    let range: String
    let granularity: String?
    let from: String
    let until: String
    let totals: Totals
    let buckets: [Bucket]

    struct Totals: Codable, Sendable {
        let requestCount: Int
        let usageUSD: Double?

        enum CodingKeys: String, CodingKey {
            case requestCount = "request_count"
            case usageUSD = "usage_usd"
        }
    }

    struct Bucket: Codable, Sendable {
        let from: String
        let until: String
        let partial: Bool?
        let requestCount: Int
        let usageUSD: Double?

        enum CodingKeys: String, CodingKey {
            case from, until, partial
            case requestCount = "request_count"
            case usageUSD = "usage_usd"
        }
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
