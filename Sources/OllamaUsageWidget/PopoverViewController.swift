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

        stack.addArrangedSubview(makeRow(title: "Weekly", value: String(format: "%.1f%%", weekly.usage * 100)))
        let sessionValue: String
        if let since = controller?.sessionSince {
            sessionValue = String(format: "%.1f%% · %@ req · since %@", session.usage * 100, grouped(session.models.reduce(0) { $0 + $1.requestCount }), timeFormatter.string(from: since))
        } else {
            sessionValue = String(format: "%.1f%% · %@ req", session.usage * 100, grouped(session.models.reduce(0) { $0 + $1.requestCount }))
        }
        stack.addArrangedSubview(makeRow(title: "Session", value: sessionValue))
        stack.addArrangedSubview(makeRow(title: "Cost (4 wk)", value: "$\(cloud.activity.cost)"))

        for model in weekly.models {
            stack.addArrangedSubview(makeRow(title: model.name, value: "\(grouped(model.requestCount)) req"))
        }
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
