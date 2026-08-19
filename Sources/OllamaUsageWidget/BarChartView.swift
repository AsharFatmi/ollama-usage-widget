import AppKit

/// Horizontal bar chart cell — width is proportional to the LARGEST value in
/// the series (a chart), not to a 1.0 max (a progress bar).
@MainActor
final class BarChartView: NSView {
    var fraction: CGFloat = 0 {
        didSet { needsDisplay = true }
    }
    var color: NSColor = .systemBlue {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 310, height: 8) }

    override func draw(_ dirtyRect: NSRect) {
        let track = NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4)
        NSColor.quaternaryLabelColor.setFill()
        track.fill()

        guard fraction > 0 else { return }
        let w = max(bounds.width * min(max(fraction, 0), 1), 2)
        let bar = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: w, height: bounds.height), xRadius: 4, yRadius: 4)
        color.setFill()
        bar.fill()
    }
}
