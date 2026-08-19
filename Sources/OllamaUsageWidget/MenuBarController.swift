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
    private var previousWeeklyUsage: Double?

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
            button.image = makePillImage(weekly: nil, session: nil)
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

    /// Re-render the popover without refetching (used by section toggles).
    func refreshPopoverOnly() {
        (popover.contentViewController as? PopoverViewController)?.reloadData()
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
                    // Track daily activity: positive deltas of the weekly usage
                    // number go into the activity store for the 7-day chart.
                    if let prev = previousWeeklyUsage, cloud.limits.weekly.usage > prev {
                        ActivityStore.add(delta: cloud.limits.weekly.usage - prev)
                    }
                    previousWeeklyUsage = cloud.limits.weekly.usage
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
        let weekly = lastCloud?.limits.weekly.usage
        let session = lastCloud?.limits.session.usage
        statusItem.button?.image = makePillImage(weekly: weekly, session: session)
    }

    /// Black iPhone-island-style pill: 🦙 + weekly % + session %.
    private func makePillImage(weekly: Double?, session: Double?) -> NSImage {
        let mono = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        let emojiFont = NSFont.systemFont(ofSize: 12)
        let white = NSColor.white
        let dim = NSColor.white.withAlphaComponent(0.75)

        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: "🦙 ", attributes: [.font: emojiFont, .foregroundColor: white]))
        if let session {
            str.append(NSAttributedString(string: String(format: "%.1f%%", session * 100), attributes: [.font: mono, .foregroundColor: white]))
            if let weekly {
                str.append(NSAttributedString(string: " · ", attributes: [.font: mono, .foregroundColor: dim]))
                str.append(NSAttributedString(string: String(format: "%.1f%%", weekly * 100), attributes: [.font: mono, .foregroundColor: dim]))
            }
        } else {
            str.append(NSAttributedString(string: "—", attributes: [.font: mono, .foregroundColor: white]))
        }

        let textSize = str.boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).size
        let padX: CGFloat = 18
        let padY: CGFloat = 6
        let size = NSSize(width: ceil(textSize.width) + padX * 2, height: ceil(textSize.height) + padY * 2)

        let image = NSImage(size: size)
        image.lockFocus()
        let pill = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: size.height / 2, yRadius: size.height / 2)
        NSColor.black.setFill()
        pill.fill()
        // Vertically center the text so emoji ascenders never clip at the top.
        let drawY = (size.height - textSize.height) / 2
        str.draw(at: NSPoint(x: padX, y: drawY))
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
