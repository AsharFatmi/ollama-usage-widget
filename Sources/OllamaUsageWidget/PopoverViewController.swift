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
            label.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            stack.addArrangedSubview(label)
        } else {
            let label = NSTextField(labelWithString: "Loading…")
            label.textColor = .secondaryLabelColor
            stack.addArrangedSubview(label)
        }
    }

    private func addCloudRows(_ cloud: UsageResponse, to stack: NSStackView) {
        let weekly = cloud.limits.weekly
        let session = cloud.limits.session

        stack.addArrangedSubview(makeRow(title: "Weekly", value: String(format: "%.3f", weekly.usage)))
        stack.addArrangedSubview(makeRow(
            title: "Session",
            value: String(format: "%.3f · %@ req", session.usage, grouped(session.models.reduce(0) { $0 + $1.requestCount }))
        ))
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
