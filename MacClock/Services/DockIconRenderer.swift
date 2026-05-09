import AppKit

@MainActor
final class DockIconRenderer {
    private var timer: Timer?
    private var lastRenderedMinute: Int = -1
    var use24Hour: Bool = false

    /// Nonisolated so SwiftUI `@State` default-value evaluation (which runs
    /// in a synchronous nonisolated context under Swift 5.10) can construct
    /// this. The stored properties initialise to MainActor-safe defaults
    /// (nil, -1, false) so no actor-isolated work happens here.
    nonisolated init() {}

    func startUpdating() {
        updateIcon()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndUpdate()
            }
        }
    }

    func stopUpdating() {
        timer?.invalidate()
        timer = nil
        NSApp.applicationIconImage = nil
    }

    private func checkAndUpdate() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let current = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if current != lastRenderedMinute {
            lastRenderedMinute = current
            updateIcon()
        }
    }

    private func updateIcon() {
        let image = renderTimeIcon()
        NSApp.applicationIconImage = image
    }

    // MARK: - Seven-segment rendering

    // Segment map: which segments are lit for each digit 0-9
    // Segments: a=top, b=top-right, c=bottom-right, d=bottom, e=bottom-left, f=top-left, g=middle
    private static let segmentMap: [[Bool]] = [
        // a     b     c     d     e     f     g
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true],  // 2
        [true,  true,  true,  true,  false, false, true],  // 3
        [false, true,  true,  false, false, true,  true],  // 4
        [true,  false, true,  true,  false, true,  true],  // 5
        [true,  false, true,  true,  true,  true,  true],  // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true],  // 8
        [true,  true,  true,  true,  false, true,  true],  // 9
    ]

    private func renderTimeIcon() -> NSImage {
        let s: CGFloat = 512
        let image = NSImage(size: NSSize(width: s, height: s), flipped: true) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // Background rounded rect with gradient
            let bgPath = CGPath(roundedRect: CGRect(x: 16, y: 16, width: 480, height: 480),
                                cornerWidth: 96, cornerHeight: 96, transform: nil)
            ctx.addPath(bgPath)
            ctx.clip()

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bgColors = [
                CGColor(srgbRed: 0x1a/255.0, green: 0x1a/255.0, blue: 0x2e/255.0, alpha: 1),
                CGColor(srgbRed: 0x16/255.0, green: 0x21/255.0, blue: 0x3e/255.0, alpha: 1),
            ]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0, 1]) {
                ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: s, y: s), options: [])
            }
            ctx.resetClip()

            // Get current time digits
            let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
            var hour = comps.hour ?? 0
            let minute = comps.minute ?? 0

            if !self.use24Hour {
                hour = hour % 12
                if hour == 0 { hour = 12 }
            }

            let d0 = hour / 10
            let d1 = hour % 10
            let d2 = minute / 10
            let d3 = minute % 10

            // Segment dimensions (from SVG)
            let segW: CGFloat = 45   // horizontal segment width
            let segH: CGFloat = 11   // segment thickness
            let segVH: CGFloat = 55  // vertical segment height
            let digitW: CGFloat = 64 // total digit cell width
            let digitH: CGFloat = 141
            let digitSpacing: CGFloat = 80
            let colonOffset: CGFloat = 155
            let digit3Offset: CGFloat = 185
            let digit4Offset: CGFloat = 265
            let totalW: CGFloat = digit4Offset + digitW
            let originX: CGFloat = (s - totalW) / 2
            let originY: CGFloat = (s - digitH) / 2

            let ghostColor = CGColor(srgbRed: 0x0a/255.0, green: 0x2a/255.0, blue: 0x3f/255.0, alpha: 0.5)
            let litColor = CGColor(srgbRed: 0x00/255.0, green: 0xd4/255.0, blue: 0xff/255.0, alpha: 0.9)
            let glowColor = CGColor(srgbRed: 0x00/255.0, green: 0xd4/255.0, blue: 0xff/255.0, alpha: 0.6)
            let rx: CGFloat = 4

            let digitOffsets: [CGFloat] = [0, digitSpacing, digit3Offset, digit4Offset]
            let digits = [d0, d1, d2, d3]

            // Draw ghost segments for all 4 digits
            for i in 0..<4 {
                let dx = originX + digitOffsets[i]
                let dy = originY
                self.drawAllSegments(ctx: ctx, x: dx, y: dy, color: ghostColor,
                                     segW: segW, segH: segH, segVH: segVH, rx: rx)
            }

            // Draw ghost colon
            let colonX = originX + colonOffset + 12
            self.drawCircle(ctx: ctx, cx: colonX, cy: originY + 42, r: 9, color: ghostColor)
            self.drawCircle(ctx: ctx, cx: colonX, cy: originY + 100, r: 9, color: ghostColor)

            // Draw lit segments with glow
            ctx.setShadow(offset: .zero, blur: 8, color: glowColor)

            for i in 0..<4 {
                let digit = digits[i]
                // Skip leading zero in 12-hour mode
                if i == 0 && !self.use24Hour && d0 == 0 { continue }

                let dx = originX + digitOffsets[i]
                let dy = originY
                let segs = Self.segmentMap[digit]
                self.drawLitSegments(ctx: ctx, x: dx, y: dy, segments: segs, color: litColor,
                                     segW: segW, segH: segH, segVH: segVH, rx: rx)
            }

            // Draw lit colon
            self.drawCircle(ctx: ctx, cx: colonX, cy: originY + 42, r: 9, color: litColor)
            self.drawCircle(ctx: ctx, cx: colonX, cy: originY + 100, r: 9, color: litColor)

            ctx.setShadow(offset: .zero, blur: 0, color: nil)

            return true
        }

        return image
    }

    private func drawAllSegments(ctx: CGContext, x: CGFloat, y: CGFloat, color: CGColor,
                                 segW: CGFloat, segH: CGFloat, segVH: CGFloat, rx: CGFloat) {
        ctx.setFillColor(color)
        // a - top horizontal
        ctx.fill(roundedRect: CGRect(x: x + 8, y: y, width: segW, height: segH), rx: rx)
        // b - top-right vertical
        ctx.fill(roundedRect: CGRect(x: x + 53, y: y + 8, width: segH, height: segVH), rx: rx)
        // c - bottom-right vertical
        ctx.fill(roundedRect: CGRect(x: x + 53, y: y + 76, width: segH, height: segVH), rx: rx)
        // d - bottom horizontal
        ctx.fill(roundedRect: CGRect(x: x + 8, y: y + 130, width: segW, height: segH), rx: rx)
        // e - bottom-left vertical
        ctx.fill(roundedRect: CGRect(x: x, y: y + 76, width: segH, height: segVH), rx: rx)
        // f - top-left vertical
        ctx.fill(roundedRect: CGRect(x: x, y: y + 8, width: segH, height: segVH), rx: rx)
        // g - middle horizontal
        ctx.fill(roundedRect: CGRect(x: x + 8, y: y + 65, width: segW, height: segH), rx: rx)
    }

    private func drawLitSegments(ctx: CGContext, x: CGFloat, y: CGFloat, segments: [Bool], color: CGColor,
                                 segW: CGFloat, segH: CGFloat, segVH: CGFloat, rx: CGFloat) {
        ctx.setFillColor(color)
        // Segment positions: [a, b, c, d, e, f, g]
        let rects: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (x + 8,  y,       segW, segH),   // a
            (x + 53, y + 8,   segH, segVH),  // b
            (x + 53, y + 76,  segH, segVH),  // c
            (x + 8,  y + 130, segW, segH),   // d
            (x,      y + 76,  segH, segVH),  // e
            (x,      y + 8,   segH, segVH),  // f
            (x + 8,  y + 65,  segW, segH),   // g
        ]
        for (i, on) in segments.enumerated() where on {
            let (rx2, ry, rw, rh) = rects[i]
            ctx.fill(roundedRect: CGRect(x: rx2, y: ry, width: rw, height: rh), rx: rx)
        }
    }

    private func drawCircle(ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, color: CGColor) {
        ctx.setFillColor(color)
        ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }
}

// Helper for drawing rounded rects via CGContext
private extension CGContext {
    func fill(roundedRect rect: CGRect, rx: CGFloat) {
        let path = CGPath(roundedRect: rect, cornerWidth: rx, cornerHeight: rx, transform: nil)
        addPath(path)
        fillPath()
    }
}
