#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/app/Resources/icon.svg"
ICONSET="$ROOT/build/AppIcon.iconset"
ICNS="$ROOT/app/Resources/AppIcon.icns"

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

# Use Swift + AppKit to render SVG to PNGs (zero external dependencies)
swift - "$SVG" "$ICONSET" <<'SWIFT'
import AppKit
let args = CommandLine.arguments
let svgURL = URL(fileURLWithPath: args[1])
let outDir = args[2]
let svgData = try Data(contentsOf: svgURL)
let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    let img = NSImage(data: svgData)!
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    img.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try png.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}
SWIFT

iconutil --convert icns --output "$ICNS" "$ICONSET"
rm -rf "$ICONSET"
echo "✓ $ICNS"
