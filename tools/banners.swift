// Renders social/Reddit banners from app screenshots.
//   swiftc -O tools/banners.swift -o /tmp/banners && /tmp/banners <screenshots-dir> <out-dir> <AppIcon.icns> "App Name"
// Screenshots expected in <screenshots-dir>: popular-dark, popular-light, game-dark, game-light,
// tabs-dark, logpanel-light, logpanel-dark, popup-light, rail-dark (.png)
import AppKit

let args = CommandLine.arguments
guard args.count >= 4 else { print("usage: banners <screenshots> <out> <icon.icns> [name]"); exit(1) }
let shotsDir = args[1], outDir = args[2], iconPath = args[3]
let appName = args.count > 4 ? args[4] : "Backloggd for Mac"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let pink = NSColor(red: 0.88, green: 0.27, blue: 0.50, alpha: 1)
let teal = NSColor(red: 0.36, green: 0.80, blue: 0.72, alpha: 1)

func load(_ n: String) -> NSImage { NSImage(contentsOfFile: "\(shotsDir)/\(n).png")! }
let icon = NSImage(contentsOfFile: iconPath)!

func render(_ name: String, _ w: Int, _ h: Int, _ body: (CGFloat, CGFloat) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let base = NSGraphicsContext(bitmapImageRep: rep)!
    base.cgContext.translateBy(x: 0, y: CGFloat(h)); base.cgContext.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: base.cgContext, flipped: true)
    body(CGFloat(w), CGFloat(h))
    NSGraphicsContext.current = nil
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    print("wrote \(name).png \(w)x\(h)")
}

func background(_ w: CGFloat, _ h: CGFloat) {
    NSGradient(colors: [NSColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1), NSColor(red: 0.11, green: 0.12, blue: 0.17, alpha: 1)])!
        .draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: 35)
    NSGradient(colors: [pink.withAlphaComponent(0.38), pink.withAlphaComponent(0)])!
        .draw(fromCenter: NSPoint(x: w * 0.88, y: h * 0.05), radius: 0, toCenter: NSPoint(x: w * 0.88, y: h * 0.05), radius: w * 0.45, options: [])
    NSGradient(colors: [teal.withAlphaComponent(0.26), teal.withAlphaComponent(0)])!
        .draw(fromCenter: NSPoint(x: w * 0.05, y: h * 1.0), radius: 0, toCenter: NSPoint(x: w * 0.05, y: h * 1.0), radius: w * 0.4, options: [])
}

@discardableResult
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular,
          color: NSColor = .white, align: NSTextAlignment = .left, line: CGFloat = 1.1) -> CGFloat {
    let p = NSMutableParagraphStyle(); p.alignment = align; p.lineBreakMode = .byWordWrapping
    p.minimumLineHeight = size * line; p.maximumLineHeight = size * line
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: p])
    let r = a.boundingRect(with: NSSize(width: width, height: 2000), options: [.usesLineFragmentOrigin])
    a.draw(with: NSRect(x: x, y: y, width: width, height: ceil(r.height) + 4), options: [.usesLineFragmentOrigin])
    return ceil(r.height)
}

func chip(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 28, tint: NSColor = .white) -> CGFloat {
    let font = NSFont.systemFont(ofSize: size, weight: .semibold)
    let tw = (s as NSString).size(withAttributes: [.font: font]).width
    let rect = NSRect(x: x, y: y, width: tw + size * 1.4, height: size * 1.9)
    tint.withAlphaComponent(0.12).setFill()
    NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2).fill()
    tint.withAlphaComponent(0.25).setStroke()
    let b = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: rect.height / 2, yRadius: rect.height / 2); b.lineWidth = 1.5; b.stroke()
    (s as NSString).draw(at: NSPoint(x: rect.minX + size * 0.7, y: rect.minY + (rect.height - size * 1.2) / 2),
                         withAttributes: [.font: font, .foregroundColor: tint])
    return rect.width
}

/// Draws a screenshot (optionally a cropped part of it, given as fractions) with a soft shadow, rotated around its centre.
func shot(_ img: NSImage, _ rect: NSRect, crop: NSRect? = nil, radius: CGFloat = 0, rotate: CGFloat = 0, shadow: Bool = true) {
    let ctx = NSGraphicsContext.current!
    ctx.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: rect.midX, yBy: rect.midY); t.rotate(byDegrees: rotate); t.translateX(by: -rect.midX, yBy: -rect.midY)
    t.concat()
    if shadow {
        let sh = NSShadow(); sh.shadowColor = NSColor.black.withAlphaComponent(0.6); sh.shadowBlurRadius = 60; sh.shadowOffset = NSSize(width: 0, height: -28)
        sh.set()
    }
    let s = img.size
    var from = NSRect(origin: .zero, size: s)
    if let c = crop { from = NSRect(x: c.minX * s.width, y: s.height - (c.minY + c.height) * s.height, width: c.width * s.width, height: c.height * s.height) }
    if radius > 0 {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        // fill first so the shadow is cast by the clip shape, then draw the image inside it
        NSColor.black.setFill(); path.fill()
        ctx.saveGraphicsState(); NSShadow().set(); path.addClip()
        img.draw(in: rect, from: from, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        ctx.restoreGraphicsState()
    } else {
        img.draw(in: rect, from: from, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
    ctx.restoreGraphicsState()
}

let aspect: CGFloat = 2940.0 / 1666.0
let nameParts = appName.split(separator: " ", maxSplits: 1).map(String.init)
let line1 = nameParts.first ?? appName
let line2 = nameParts.count > 1 ? nameParts[1] : ""

// ---------- 1. Hero, 16:9 ----------
render("reddit-hero-1920x1080", 1920, 1080) { w, h in
    background(w, h)
    shot(load("popular-dark"), NSRect(x: 820, y: 120, width: 1180, height: 1180 / aspect), rotate: -3)
    shot(load("game-light"), NSRect(x: 900, y: 470, width: 1000, height: 1000 / aspect), rotate: 2.5)
    icon.draw(in: NSRect(x: 100, y: 120, width: 140, height: 140))
    var y: CGFloat = 300
    y += text(line1, 100, y, 800, size: 124, weight: .heavy, line: 1.0)
    y += text(line2, 100, y, 800, size: 124, weight: .heavy, color: pink, line: 1.0) + 26
    y += text("Your backlog, in a real Mac app.", 100, y, 700, size: 46, weight: .medium, color: NSColor.white.withAlphaComponent(0.82), line: 1.2) + 34
    var x: CGFloat = 100
    x += chip("Free & open source", x, y) + 14
    x += chip("Day & night", x, y, tint: teal)
    x = 100; y += 74
    x += chip("Tabs", x, y) + 14
    x += chip("Notifications", x, y) + 14
    _ = chip("Apple Silicon + Intel", x, y)
    text("Unofficial app · not affiliated with Backloggd", 100, 984, 800, size: 26, color: NSColor.white.withAlphaComponent(0.5))
}

// ---------- 2. Features, 16:9 ----------
render("reddit-features-1920x1080", 1920, 1080) { w, h in
    background(w, h)
    text("Built for the Mac", 90, 60, 1200, size: 76, weight: .heavy)
    text("Everything you like about Backloggd, in a proper app.", 90, 150, 1400, size: 34, weight: .medium, color: NSColor.white.withAlphaComponent(0.72))
    let cards: [(String, String, String, NSPoint, CGFloat)] = [
        ("tabs-dark", "Tabs", "⌘T for a new tab, ⌘-click opens links in one. Tabs return next launch.", NSPoint(x: 0.5, y: 0.23), 1.0),
        ("popular-light", "Day & night mode", "Follows macOS, or switch with ⇧⌘L. Fully restyled, not just inverted.", NSPoint(x: 0.5, y: 0.23), 1.0),
        ("logpanel-light", "Log a game fast", "⌘L opens Quick Log from anywhere. Menu-bar item and a global hotkey too.", NSPoint(x: 0.5, y: 0.50), 1.0),
        ("popup-light", "Actions on every cover", "Hover a cover to play, backlog, log or add it to a list.", NSPoint(x: 0.5, y: 0.52), 0.62),
    ]
    let cw: CGFloat = 850, ch: CGFloat = 380
    for (i, c) in cards.enumerated() {
        let cx = 90 + CGFloat(i % 2) * (cw + 40), cy = 240 + CGFloat(i / 2) * (ch + 40)
        let card = NSRect(x: cx, y: cy, width: cw, height: ch)
        NSColor.white.withAlphaComponent(0.06).setFill()
        NSBezierPath(roundedRect: card, xRadius: 28, yRadius: 28).fill()
        let boxW = cw - 36, boxH: CGFloat = 210
        let fh = c.4 * aspect * boxH / boxW
        let crop = NSRect(x: c.3.x - c.4 / 2, y: min(max(c.3.y - fh / 2, 0), 1 - fh), width: c.4, height: fh)
        shot(load(c.0), NSRect(x: cx + 18, y: cy + 18, width: boxW, height: boxH), crop: crop, radius: 16, shadow: false)
        text(c.1, cx + 30, cy + 244, cw - 60, size: 36, weight: .bold)
        text(c.2, cx + 30, cy + 292, cw - 60, size: 24, color: NSColor.white.withAlphaComponent(0.7), line: 1.25)
    }
}

// ---------- 3. Day / night split, square ----------
render("reddit-daynight-1080x1080", 1080, 1080) { w, h in
    background(w, h)
    icon.draw(in: NSRect(x: 40, y: 44, width: 96, height: 96))
    text("Day & Night", 158, 34, 880, size: 84, weight: .heavy)
    text(appName, 160, 132, 880, size: 34, weight: .semibold, color: pink)
    let fw = w - 80, fh = fw / aspect
    let frame = NSRect(x: 40, y: 250, width: fw, height: fh)
    let ctx = NSGraphicsContext.current!
    ctx.saveGraphicsState()
    let shd = NSShadow(); shd.shadowColor = NSColor.black.withAlphaComponent(0.55); shd.shadowBlurRadius = 50; shd.shadowOffset = NSSize(width: 0, height: -24); shd.set()
    NSColor.black.setFill(); NSBezierPath(roundedRect: frame, xRadius: 26, yRadius: 26).fill()
    ctx.restoreGraphicsState()
    ctx.saveGraphicsState()
    NSBezierPath(roundedRect: frame, xRadius: 26, yRadius: 26).addClip()
    load("popular-dark").draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    let mid = frame.midX + 40
    let diag = NSBezierPath()
    diag.move(to: NSPoint(x: mid + 60, y: frame.minY)); diag.line(to: NSPoint(x: frame.maxX, y: frame.minY))
    diag.line(to: NSPoint(x: frame.maxX, y: frame.maxY)); diag.line(to: NSPoint(x: mid - 60, y: frame.maxY)); diag.close()
    ctx.saveGraphicsState(); diag.addClip()
    load("popular-light").draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    ctx.restoreGraphicsState()
    NSColor.white.withAlphaComponent(0.9).setStroke()
    let line = NSBezierPath(); line.move(to: NSPoint(x: mid + 60, y: frame.minY)); line.line(to: NSPoint(x: mid - 60, y: frame.maxY)); line.lineWidth = 4; line.stroke()
    ctx.restoreGraphicsState()
    text("Follows macOS, or flip it with ⇧⌘L.", 40, frame.maxY + 44, 1000, size: 40, weight: .semibold, color: NSColor.white.withAlphaComponent(0.9))
    var x: CGFloat = 40
    let cy = frame.maxY + 120
    x += chip("Free", x, cy, size: 26) + 12
    x += chip("Tabs", x, cy, size: 26) + 12
    x += chip("Notifications", x, cy, size: 26, tint: teal) + 12
    _ = chip("Intel + Apple Silicon", x, cy, size: 26)
    text("Unofficial app · not affiliated with Backloggd", 40, 1018, 1000, size: 22, color: NSColor.white.withAlphaComponent(0.5))
}

// ---------- 4. Wide header ----------
render("reddit-header-1920x400", 1920, 400) { w, h in
    background(w, h)
    icon.draw(in: NSRect(x: 90, y: 90, width: 180, height: 180))
    text(appName, 310, 92, 900, size: 80, weight: .heavy, line: 1.0)
    text("A native Mac app for your game backlog", 314, 200, 880, size: 34, weight: .medium, color: NSColor.white.withAlphaComponent(0.8))
    var x: CGFloat = 314
    x += chip("Unofficial", x, 276, size: 24) + 12
    _ = chip("Free & open source", x, 276, size: 24, tint: teal)
    shot(load("popular-dark"), NSRect(x: 1230, y: 60, width: 520, height: 520 / aspect), rotate: -4)
    shot(load("popular-light"), NSRect(x: 1430, y: 130, width: 520, height: 520 / aspect), rotate: 3)
}

// ---------- 5. Collapsible sidebar / tabs showcase, 16:9 ----------
render("reddit-showcase-1920x1080", 1920, 1080) { w, h in
    background(w, h)
    let sw: CGFloat = 1500
    shot(load("tabs-dark"), NSRect(x: (w - sw) / 2, y: 190, width: sw, height: sw / aspect), radius: 0)
    text("Tabs, sidebar, notifications.", 0, 52, w, size: 74, weight: .heavy, align: .center)
    text("\(appName) — free, open source, unofficial.", 0, 138, w, size: 32, weight: .medium, color: NSColor.white.withAlphaComponent(0.7), align: .center)
}
