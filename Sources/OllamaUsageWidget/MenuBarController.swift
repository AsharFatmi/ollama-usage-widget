import AppKit

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let fetcher = UsageFetcher()
    private var timer: Timer?

    private(set) var lastCloud: UsageResponse?
    private(set) var lastLocal: PsResponse?
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?
    private(set) var dailyUsage: Double = 0
    private var previousWeeklyUsage: Double?
    private var dailyDay: Int?
    private var lastNudgeAt: Date?
    private var lastNudgedDaily: Double = 0
    private let nudgeWindow = NudgeWindow(entries: [("Daily", 0), ("Weekly", 0), ("Session (5h)", 0)])

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupStatusItem()
        setupPopover()
        startTimer()
        refresh()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.title = "🦙 —"
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = PopoverViewController(controller: self)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            refresh()
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func refresh() {
        Task {
            let key = KeychainStore.read() ?? EnvFileReader.ollamaKey()
            if let key {
                do {
                    let cloud = try await fetcher.fetchCloudUsage(apiKey: key)
                    trackDaily(weekly: cloud.limits.weekly.usage)
                    lastCloud = cloud
                    lastError = nil
                } catch {
                    lastError = "Cloud: \(error.localizedDescription)"
                }
            } else {
                lastError = "No API key set — use Set Key… in the popover"
            }
            do {
                lastLocal = try await fetcher.fetchLocalProcesses()
            } catch {
                lastLocal = nil // local Ollama offline is normal; don't clobber lastError
            }
            lastUpdated = Date()
            updateStatusTitle()
            (popover.contentViewController as? PopoverViewController)?.reloadData()
        }
    }

    private func updateStatusTitle() {
        let title: String
        if let weekly = lastCloud?.limits.weekly.usage {
            title = String(format: "🦙 %.1f%%", weekly * 100)
        } else {
            title = "🦙 —"
        }
        statusItem.button?.title = title
    }

    /// The API exposes no daily window — accumulate the 5-min deltas of the
    /// weekly number since local midnight. Resets each day.
    private func trackDaily(weekly: Double) {
        let now = Date()
        let day = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
        if dailyDay != day {
            dailyDay = day
            dailyUsage = 0
            previousWeeklyUsage = nil
        }
        if let prev = previousWeeklyUsage {
            let delta = weekly - prev
            if delta > 0 { dailyUsage += delta }
        }
        previousWeeklyUsage = weekly
        maybeNudge(now: now)
    }

    /// Show the Dynamic-Island-style pill when the daily usage crosses a
    /// whole-percent boundary (max once per 5 minutes).
    private func maybeNudge(now: Date) {
        let crossed = Int(dailyUsage * 100) > Int(lastNudgedDaily * 100)
        let cooldown = lastNudgeAt.map { now.timeIntervalSince($0) > 300 } ?? true
        guard crossed, cooldown else { return }
        lastNudgeAt = now
        lastNudgedDaily = dailyUsage

        let weekly = lastCloud?.limits.weekly.usage ?? 0
        let session = lastCloud?.limits.session.usage ?? 0
        nudgeWindow.update(entries: [
            ("Daily", dailyUsage),
            ("Weekly", weekly),
            ("Session (5h)", session),
        ])
        nudgeWindow.setDetail(String(format: "Daily %.1f%% · Weekly %.1f%% · Session %.1f%%", dailyUsage * 100, weekly * 100, session * 100))
        nudgeWindow.nudge()
    }
}
