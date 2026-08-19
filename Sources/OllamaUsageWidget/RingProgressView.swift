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
