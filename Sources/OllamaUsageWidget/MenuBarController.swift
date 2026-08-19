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
    private let nudgeWindow = NudgeWindow(entries: [("Weekly", 0), ("Session (5h)", 0)])

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
            button.title = ""
            button.image = makePillImage(percent: nil)
            button.imagePosition = .imageOnly
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
                    lastCloud = try await fetcher.fetchCloudUsage(apiKey: key)
                    lastError = nil
                    maybeNudge(now: Date())
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
        let percent = lastCloud?.limits.weekly.usage
        statusItem.button?.image = makePillImage(percent: percent)
    }

    /// Black iPhone-island-style pill with the weekly percentage inside.
    private func makePillImage(percent: Double?) -> NSImage {
        let text: String
        if let percent {
            text = String(format: "%.1f%%", percent * 100)
        } else {
            text = "—"
        }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()
        let padX: CGFloat = 14
        let padY: CGFloat = 5
        let size = NSSize(width: textSize.width + padX * 2, height: textSize.height + padY * 2)

        let image = NSImage(size: size)
        image.lockFocus()
        let pill = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: size.height / 2, yRadius: size.height / 2)
        NSColor.black.setFill()
        pill.fill()
        str.draw(at: NSPoint(x: padX, y: padY))
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    /// Show the Dynamic-Island-style pill when the weekly usage crosses a
    /// whole-percent boundary (max once per 5 minutes).
    private func maybeNudge(now: Date) {
        let weekly = lastCloud?.limits.weekly.usage ?? 0
        let session = lastCloud?.limits.session.usage ?? 0
        nudgeWindow.update(entries: [
            ("Weekly", weekly),
            ("Session (5h)", session),
        ])
        nudgeWindow.setDetail(String(format: "Weekly %.1f%% · Session %.1f%%", weekly * 100, session * 100))
        nudgeWindow.nudge()
    }
}
