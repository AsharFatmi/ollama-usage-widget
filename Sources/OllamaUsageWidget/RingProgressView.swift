import AppKit

/// Hollow circular progress ring (activity-ring style).
@MainActor
final class RingProgressView: NSView {
    var progress: Double = 0 {
        didSet { needsDisplay = true }
    }
    var ringColor: NSColor = .systemGreen {
        didSet { needsDisplay = true }
    }
    var trackColor: NSColor = NSColor.white.withAlphaComponent(0.15) {
        didSet { needsDisplay = true }
    }
    var lineWidth: CGFloat = 6

    override var intrinsicContentSize: NSSize { NSSize(width: 64, height: 64) }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Track — full hollow circle
        let track = NSBezierPath()
        track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        track.lineWidth = lineWidth
        trackColor.setStroke()
        track.stroke()

        // Progress arc — starts at 12 o'clock, sweeps clockwise
        let clamped = min(max(progress, 0), 1)
        guard clamped > 0 else { return }
        let arc = NSBezierPath()
        arc.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - clamped * 360, clockwise: true)
        arc.lineWidth = lineWidth
        arc.lineCapStyle = .round
        ringColor.setStroke()
        arc.stroke()
    }
}

/// Ring with the percentage + title centered inside the hollow.
@MainActor
final class RingCellView: NSView {
    private let ring = RingProgressView()
    private let percentLabel = NSTextField(labelWithString: "")
    private let captionLabel = NSTextField(labelWithString: "")

    override var intrinsicContentSize: NSSize { NSSize(width: 150, height: 64) }

    init(title: String, percent: Double) {
        super.init(frame: .zero)

        ring.progress = percent
        ring.lineWidth = 6
        ring.ringColor = RingCellView.color(for: percent)

        percentLabel.stringValue = String(format: "%.1f%%", percent * 100)
        percentLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        percentLabel.alignment = .center
        percentLabel.textColor = .labelColor

        captionLabel.stringValue = title
        captionLabel.font = .systemFont(ofSize: 9)
        captionLabel.textColor = .secondaryLabelColor
        captionLabel.alignment = .center

        addSubview(ring)
        addSubview(percentLabel)
        addSubview(captionLabel)
        ring.translatesAutoresizingMaskIntoConstraints = false
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: centerXAnchor),
            ring.topAnchor.constraint(equalTo: topAnchor),
            ring.widthAnchor.constraint(equalToConstant: 64),
            ring.heightAnchor.constraint(equalToConstant: 64),
            percentLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            captionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            captionLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static func color(for percent: Double) -> NSColor {
        switch percent {
        case ..<0.5: return .systemGreen
        case ..<0.8: return .systemYellow
        default: return .systemRed
        }
    }
}
