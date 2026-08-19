import AppKit

/// 7-day activity line chart. Values are daily deltas of the weekly usage
/// number (persisted by the app since the API exposes no history).
@MainActor
final class ActivityChartView: NSView {
    /// 7 values, oldest → newest (usage fraction per day, e.g. 0.034).
    var values: [Double] = [] {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 310, height: 90) }

    override func draw(_ dirtyRect: NSRect) {
        guard values.count > 1 else {
            let empty = "collecting data…" as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
            empty.draw(at: NSPoint(x: 8, y: bounds.midY - 8), withAttributes: attrs)
            return
        }

        let maxVal = max(values.max() ?? 0, 0.0001)
        let padX: CGFloat = 4
        let padY: CGFloat = 6
        let w = bounds.width - padX * 2
        let h = bounds.height - padY * 2

        // Grid lines (25/50/75/100%)
        let gridAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 8), .foregroundColor: NSColor.tertiaryLabelColor]
        for f in [0.25, 0.5, 0.75, 1.0] {
            let y = padY + h * (1 - f)
            let line = NSBezierPath()
            line.move(to: NSPoint(x: padX, y: y))
            line.line(to: NSPoint(x: bounds.width - padX, y: y))
            line.lineWidth = 0.5
            NSColor.quaternaryLabelColor.setStroke()
            line.stroke()
        }

        // Area fill under the line
        let n = values.count
        let step = w / CGFloat(n - 1)
        let pts: [NSPoint] = values.enumerated().map { i, v in
            NSPoint(x: padX + CGFloat(i) * step, y: padY + h * CGFloat(v / maxVal))
        }
        let area = NSBezierPath()
        area.move(to: NSPoint(x: pts[0].x, y: padY))
        for p in pts { area.line(to: p) }
        area.line(to: NSPoint(x: pts[n - 1].x, y: padY))
        area.close()
        NSColor.systemBlue.withAlphaComponent(0.15).setFill()
        area.fill()

        // Line
        let line = NSBezierPath()
        line.move(to: pts[0])
        for p in pts.dropFirst() { line.line(to: p) }
        line.lineWidth = 2
        line.lineCapStyle = .round
        line.lineJoinStyle = .round
        NSColor.systemBlue.setStroke()
        line.stroke()

        // Points
        for p in pts {
            let dot = NSBezierPath(ovalIn: NSRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4))
            NSColor.systemBlue.setFill()
            dot.fill()
        }

        // Day labels (S M T W T F S)
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        let dayAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.secondaryLabelColor]
        for i in 0..<n {
            let x = padX + CGFloat(i) * step
            let label = days[i % 7] as NSString
            label.draw(at: NSPoint(x: x - 4, y: 1), withAttributes: dayAttrs)
        }
    }
}
