import AppKit

/// Dynamic-Island-style black pill that drops from the top of the screen,
/// shows usage rings + percentages, then slides back up.
@MainActor
final class NudgeWindow: NSPanel {
    private let ringViews: [RingProgressView]
    private let percentLabels: [NSTextField]
    private let titleLabel = NSTextField(labelWithString: "Ollama Usage")
    private let detailLabel = NSTextField(labelWithString: "")
    private var dismissWork: DispatchWorkItem?

    init(entries: [(title: String, percent: Double)]) {
        let ringCount = entries.count
        ringViews = (0..<ringCount).map { _ in RingProgressView() }
        percentLabels = (0..<ringCount).map { _ in NSTextField(labelWithString: "") }

        super.init(contentRect: NSRect(x: 0, y: 0, width: 360, height: 120),
                   styleMask: [.nonactivatingPanel, .borderless],
                   backing: .buffered,
                   defer: false)

        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .black
        isOpaque = false
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        buildUI(entries: entries)
    }

    private func buildUI(entries: [(title: String, percent: Double)]) {
        titleLabel.font = .boldSystemFont(ofSize: 13)
        titleLabel.textColor = .white
        titleLabel.alignment = .center

        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        detailLabel.alignment = .center

        let ringsRow = NSStackView()
        ringsRow.orientation = .horizontal
        ringsRow.alignment = .centerY
        ringsRow.spacing = 24

        for (i, entry) in entries.enumerated() {
            let ring = ringViews[i]
            ring.progress = entry.percent
            ring.ringColor = ringColor(for: entry.percent)

            let label = percentLabels[i]
            label.stringValue = String(format: "%.1f%%", entry.percent * 100)
            label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
            label.textColor = .white
            label.alignment = .center

            let caption = NSTextField(labelWithString: entry.title)
            caption.font = .systemFont(ofSize: 10)
            caption.textColor = NSColor.white.withAlphaComponent(0.6)
            caption.alignment = .center

            let column = NSStackView(views: [ring, label, caption])
            column.orientation = .vertical
            column.alignment = .centerX
            column.spacing = 4
            ringsRow.addArrangedSubview(column)
        }

        let root = NSStackView(views: [titleLabel, ringsRow, detailLabel])
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: contentView!.topAnchor, constant: 14),
            root.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor, constant: -20),
            root.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor, constant: -14),
        ])
    }

    private func ringColor(for percent: Double) -> NSColor {
        switch percent {
        case ..<0.5: return .systemGreen
        case ..<0.8: return .systemYellow
        default: return .systemRed
        }
    }

    func setDetail(_ text: String) {
        detailLabel.stringValue = text
    }

    /// Update ring fills + percent labels (called before each nudge).
    func update(entries: [(title: String, percent: Double)]) {
        for (i, entry) in entries.enumerated() where i < ringViews.count {
            ringViews[i].progress = entry.percent
            ringViews[i].ringColor = ringColor(for: entry.percent)
            percentLabels[i].stringValue = String(format: "%.1f%%", entry.percent * 100)
        }
    }

    /// Slide down from the top of the screen, hold, then slide back up.
    func nudge(duration: TimeInterval = 0.35, hold: TimeInterval = 4.0) {
        guard let screen = NSScreen.main else { return }
        let size = frame.size
        let x = screen.visibleFrame.midX - size.width / 2
        let topY = screen.visibleFrame.maxY
        let hiddenY = topY + 8
        let shownY = topY - size.height - 12

        setFrameOrigin(NSPoint(x: x, y: hiddenY))
        orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrameOrigin(NSPoint(x: x, y: shownY))
        }

        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = duration
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().setFrameOrigin(NSPoint(x: x, y: hiddenY))
            } completionHandler: {
                self.orderOut(nil)
            }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hold, execute: work)
    }
}
