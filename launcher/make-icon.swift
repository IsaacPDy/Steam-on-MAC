// Draws the app's own icon (a game controller on a blue tile) as a 1024px PNG.
// Steam's logo is Valve's trademark, so it is not shipped; launch.sh switches the icon
// to Steam's own once Steam is installed on the user's Mac.
// Usage: swift make-icon.swift out.png
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// macOS icon grid: 824px tile centred in 1024, corner radius ~185.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(red: 0.09, green: 0.16, blue: 0.33, alpha: 1),
           ending: NSColor(red: 0.10, green: 0.45, blue: 0.75, alpha: 1))!.draw(in: tilePath, angle: 90)

// Controller body: a wide capsule with two grips.
NSColor.white.setFill()
NSBezierPath(roundedRect: NSRect(x: 232, y: 400, width: 560, height: 260), xRadius: 130, yRadius: 130).fill()
NSBezierPath(ovalIn: NSRect(x: 222, y: 300, width: 200, height: 280)).fill()
NSBezierPath(ovalIn: NSRect(x: 602, y: 300, width: 200, height: 280)).fill()

// D-pad and buttons, cut out in the tile's colour.
NSColor(red: 0.10, green: 0.30, blue: 0.55, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 300, y: 505, width: 130, height: 40), xRadius: 10, yRadius: 10).fill()
NSBezierPath(roundedRect: NSRect(x: 345, y: 460, width: 40, height: 130), xRadius: 10, yRadius: 10).fill()
for (x, y) in [(640.0, 545.0), (700.0, 485.0)] {
    NSBezierPath(ovalIn: NSRect(x: x - 32, y: y - 32, width: 64, height: 64)).fill()
}

image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
