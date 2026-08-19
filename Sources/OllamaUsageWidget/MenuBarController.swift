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

        let textSize = str.size()
        let padX: CGFloat = 18
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
}
