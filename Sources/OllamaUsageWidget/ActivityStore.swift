import Foundation

struct DailyUsage: Codable {
    let day: String  // yyyy-MM-dd
    var value: Double
}

/// Persists daily usage deltas (change in the weekly usage number) so the
/// 7-day activity chart works even though the Ollama API exposes no history.
enum ActivityStore {
    private static let key = "activityHistory"

    static func load() -> [DailyUsage] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([DailyUsage].self, from: data) else { return [] }
        return items
    }

    private static func save(_ items: [DailyUsage]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func add(delta: Double) {
        var items = load()
        let today = dayString()
        if let i = items.firstIndex(where: { $0.day == today }) {
            items[i].value += delta
        } else {
            items.append(DailyUsage(day: today, value: delta))
        }
        items.sort { $0.day < $1.day }
        if items.count > 14 { items.removeFirst(items.count - 14) }
        save(items)
    }

    /// 7 values, oldest → newest (0 for days with no recorded activity).
    static func last7Days() -> [Double] {
        let items = load()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [Double] = []
        for i in stride(from: 6, through: 0, by: -1) {
            let day = cal.date(byAdding: .day, value: -i, to: today)!
            let ds = dayString(day)
            result.append(items.first(where: { $0.day == ds })?.value ?? 0)
        }
        return result
    }

    private static func dayString(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
