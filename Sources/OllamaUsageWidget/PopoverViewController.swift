import AppKit

@MainActor
final class PopoverViewController: NSViewController {
    private weak var controller: MenuBarController?
    private var stack: NSStackView?

    private let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var countdownTimer: Timer?
    private var nextRefreshLabel: NSTextField?

    init(controller: MenuBarController) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 260))
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
        ])
        self.stack = stack
    }

    func reloadData() {
        guard let stack else { return }
        for sub in stack.arrangedSubviews {
            stack.removeArrangedSubview(sub)
            sub.removeFromSuperview()
        }

        let header = NSTextField(labelWithString: "Ollama Cloud")
        header.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(10, after: header)

        if let cloud = controller?.lastCloud {
            addCloudRows(cloud, to: stack)
        } else if let error = controller?.lastError {
            let label = NSTextField(wrappingLabelWithString: error)
            label.textColor = .systemRed
            label.font = .systemFont(ofSize: 12)
            stack.addArrangedSubview(label)
            // Activate after the label is in the hierarchy (crash otherwise:
            // "constraint ... have no common ancestor")
            label.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        } else {
            let label = NSTextField(labelWithString: "Loading…")
            label.textColor = .secondaryLabelColor
            stack.addArrangedSubview(label)
        }

        addLocalSection(to: stack)
        addFooter(to: stack)

        // Size the popover to fit the content (preferredContentSize is honored
        // by NSPopover; resizing the view directly clips content).
        view.layoutSubtreeIfNeeded()
        let fitted = stack.fittingSize
        let height = ceil(fitted.height) + 24
        preferredContentSize = NSSize(width: 340, height: height)
    }

    private func addLocalSection(to stack: NSStackView) {
        let header = NSTextField(labelWithString: "Local Ollama")
        header.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(10, after: header)

        if let local = controller?.lastLocal, !local.models.isEmpty {
            for model in local.models {
                let vram = String(format: "%.1f GB", Double(model.sizeVram) / 1_073_741_824)
                stack.addArrangedSubview(makeRow(title: model.name, value: vram))
            }
        } else {
            let label = NSTextField(labelWithString: "Ollama not running")
            label.textColor = .secondaryLabelColor
            stack.addArrangedSubview(label)
        }
    }

    private func addFooter(to stack: NSStackView) {
        let updated = controller?.lastUpdated.map { timeFormatter.string(from: $0) } ?? "—"
        stack.addArrangedSubview(makeRow(title: "Last updated", value: updated, mono: false))

        let nextRefresh = NSTextField(labelWithString: "")
        nextRefresh.textColor = .secondaryLabelColor
        nextRefresh.font = .systemFont(ofSize: 12)
        stack.addArrangedSubview(nextRefresh)
        nextRefreshLabel = nextRefresh
        updateCountdown()
        startCountdownTimer()

        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshTapped))
        let setKeyButton = NSButton(title: "Set Key…", target: self, action: #selector(setKeyTapped))
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quitTapped))
        let buttons = NSStackView(views: [refreshButton, setKeyButton, quitButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 8
        stack.addArrangedSubview(buttons)
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateCountdown() }
        }
    }

    private func updateCountdown() {
        guard let label = nextRefreshLabel else { return }
        guard let last = controller?.lastUpdated else {
            label.stringValue = "Next refresh in —"
            return
        }
        let elapsed = Date().timeIntervalSince(last)
        let remaining = max(0, 300 - elapsed)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        label.stringValue = String(format: "Next refresh in %d:%02d", minutes, seconds)
    }

    @objc private func refreshTapped() {
        controller?.refresh()
    }

    @objc private func setKeyTapped() {
        let alert = NSAlert()
        alert.messageText = "Set Ollama API Key"
        alert.informativeText = "Enter your Ollama Cloud API key. It is stored in the macOS Keychain."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.placeholderString = "ollama-api-key"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        if KeychainStore.save(key) {
            controller?.refresh()
        }
    }

    @objc private func quitTapped() {
        NSApp.terminate(nil)
    }

    private func addCloudRows(_ cloud: UsageResponse, to stack: NSStackView) {
        let weekly = cloud.limits.weekly
        let session = cloud.limits.session

        // Section 1 — ring grid: Weekly + Session
        let ringRow = NSStackView()
        ringRow.orientation = .horizontal
        ringRow.alignment = .centerY
        ringRow.spacing = 30
        ringRow.addArrangedSubview(makeRingCell(title: "Weekly", percent: weekly.usage, value: String(format: "%.1f%%", weekly.usage * 100)))
        ringRow.addArrangedSubview(makeRingCell(
            title: "Session (5h)",
            percent: session.usage,
            value: String(format: "%.1f%%", session.usage * 100)
        ))
        stack.addArrangedSubview(ringRow)

        // Section 2 — model request counts as a horizontal bar chart
        let modelHeader = NSTextField(labelWithString: "Activity by model")
        modelHeader.font = .boldSystemFont(ofSize: 12)
        modelHeader.textColor = .secondaryLabelColor
        stack.addArrangedSubview(modelHeader)
        stack.setCustomSpacing(2, after: modelHeader)

        let maxCount = weekly.models.map { $0.requestCount }.max() ?? 0
        for model in weekly.models {
            let fraction = maxCount > 0 ? Double(model.requestCount) / Double(maxCount) : 0
            stack.addArrangedSubview(makeBarChartRow(title: model.name, value: "\(grouped(model.requestCount)) req", fraction: fraction))
        }

        stack.addArrangedSubview(makeRow(title: "Cost (4 wk)", value: "$\(cloud.activity.cost)"))

        // Section 3 — 7-day activity line chart
        let activityHeader = NSTextField(labelWithString: "7-day activity")
        activityHeader.font = .boldSystemFont(ofSize: 12)
        activityHeader.textColor = .secondaryLabelColor
        stack.addArrangedSubview(activityHeader)
        stack.setCustomSpacing(2, after: activityHeader)

        let chart = ActivityChartView()
        chart.values = ActivityStore.last7Days()
        stack.addArrangedSubview(chart)
    }

    private func makeRingCell(title: String, percent: Double, value: String) -> NSView {
        let ring = RingProgressView()
        ring.progress = percent
        ring.lineWidth = 6

        let label = NSTextField(labelWithString: value)
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        label.alignment = .center

        let caption = NSTextField(labelWithString: title)
        caption.font = .systemFont(ofSize: 10)
        caption.textColor = .secondaryLabelColor
        caption.alignment = .center

        let column = NSStackView(views: [ring, label, caption])
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 3
        return column
    }

    private func makeBarChartRow(title: String, value: String, fraction: Double) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.font = .systemFont(ofSize: 13)

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let header = NSStackView(views: [titleLabel, valueLabel])
        header.orientation = .horizontal
        header.alignment = .firstBaseline
        header.spacing = 8

        let chart = BarChartView()
        chart.fraction = CGFloat(fraction)
        chart.color = .systemBlue

        let column = NSStackView(views: [header, chart])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 2
        return column
    }

    private func grouped(_ count: Int) -> String {
        countFormatter.string(from: NSNumber(value: count)) ?? String(count)
    }

    private func makeRow(title: String, value: String, mono: Bool = true) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.font = .systemFont(ofSize: 13)

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = mono ? .monospacedDigitSystemFont(ofSize: 13, weight: .regular) : .systemFont(ofSize: 13)

        let row = NSStackView(views: [titleLabel, valueLabel])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        return row
    }
}
