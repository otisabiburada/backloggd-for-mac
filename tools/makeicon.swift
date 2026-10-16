import Cocoa
func render(_ s: Int) -> Data {
    let size = CGFloat(s)
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let inset = size * 0.08
    let rect = NSRect(x: inset, y: inset, width: size - 2*inset, height: size - 2*inset)
    let path = NSBezierPath(roundedRect: rect, xRadius: size*0.22, yRadius: size*0.22)
    NSGradient(colors: [NSColor(red: 0.13, green: 0.16, blue: 0.22, alpha: 1),
                        NSColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1)])!.draw(in: path, angle: -90)
    NSColor(white: 1, alpha: 0.08).setStroke(); path.lineWidth = size*0.006; path.stroke()
    // game controller silhouette
    let cx = size/2, cy = size*0.5
    let body = NSBezierPath(roundedRect: NSRect(x: cx - size*0.30, y: cy - size*0.13, width: size*0.60, height: size*0.26), xRadius: size*0.13, yRadius: size*0.13)
    NSColor(red: 0.36, green: 0.80, blue: 0.72, alpha: 1).setFill(); body.fill()
    NSColor(red: 0.07, green: 0.09, blue: 0.12, alpha: 1).setFill()
    // d-pad
    let dx = cx - size*0.17, dy = cy
    NSBezierPath(rect: NSRect(x: dx - size*0.07, y: dy - size*0.02, width: size*0.14, height: size*0.04)).fill()
    NSBezierPath(rect: NSRect(x: dx - size*0.02, y: dy - size*0.07, width: size*0.04, height: size*0.14)).fill()
    // buttons
    for (ox, oy) in [(0.19, 0.04), (0.25, -0.02), (0.13, -0.02), (0.19, -0.08)] {
        NSBezierPath(ovalIn: NSRect(x: cx + size*ox - size*0.025, y: cy + size*oy - size*0.025, width: size*0.05, height: size*0.05)).fill()
    }
    // progress/backlog bar under controller
    let bar = NSRect(x: cx - size*0.26, y: cy - size*0.27, width: size*0.52, height: size*0.04)
    NSColor(white: 1, alpha: 0.15).setFill(); NSBezierPath(roundedRect: bar, xRadius: size*0.02, yRadius: size*0.02).fill()
    var fill = bar; fill.size.width *= 0.62
    NSColor(red: 0.36, green: 0.80, blue: 0.72, alpha: 1).setFill(); NSBezierPath(roundedRect: fill, xRadius: size*0.02, yRadius: size*0.02).fill()
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}
let dir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
for (name, px) in [("16",16),("16@2x",32),("32",32),("32@2x",64),("128",128),("128@2x",256),("256",256),("256@2x",512),("512",512),("512@2x",1024)] {
    try! render(px).write(to: URL(fileURLWithPath: "\(dir)/icon_\(name.replacingOccurrences(of: "@2x", with: ""))x\(name.replacingOccurrences(of: "@2x", with: ""))\(name.contains("@2x") ? "@2x" : "").png"))
}
