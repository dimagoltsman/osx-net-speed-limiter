#!/usr/bin/env swift

import Cocoa

// Create icon at various sizes
let sizes = [16, 32, 64, 128, 256, 512, 1024]

// Create iconset directory
let iconsetPath = "NetLimiter.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for size in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let scale = CGFloat(size) / 100.0

    // Background - rounded rectangle with gradient
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: 2 * scale, dy: 2 * scale), xRadius: 18 * scale, yRadius: 18 * scale)

    // Gradient background (dark blue to lighter blue)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0),
        NSColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)
    ])!
    gradient.draw(in: bgPath, angle: -90)

    // Draw speedometer arc (background)
    let centerX = CGFloat(size) / 2
    let centerY = CGFloat(size) / 2 - 5 * scale
    let radius = 32 * scale

    context.setStrokeColor(NSColor(white: 0.3, alpha: 1.0).cgColor)
    context.setLineWidth(8 * scale)
    context.setLineCap(.round)
    context.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: .pi * 0.8, endAngle: .pi * 0.2, clockwise: true)
    context.strokePath()

    // Draw speedometer arc (colored - showing limit)
    let gradientColors = [
        NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0).cgColor,  // Green
        NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor,  // Yellow
        NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0).cgColor   // Red
    ]

    // Draw colored arc segments
    context.setLineWidth(6 * scale)

    // Green segment
    context.setStrokeColor(NSColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1.0).cgColor)
    context.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: .pi * 0.8, endAngle: .pi * 0.6, clockwise: true)
    context.strokePath()

    // Yellow segment
    context.setStrokeColor(NSColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0).cgColor)
    context.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: .pi * 0.6, endAngle: .pi * 0.4, clockwise: true)
    context.strokePath()

    // Red segment (dimmed - limited)
    context.setStrokeColor(NSColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 0.5).cgColor)
    context.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: .pi * 0.4, endAngle: .pi * 0.2, clockwise: true)
    context.strokePath()

    // Draw needle pointing to limit position
    let needleAngle = CGFloat.pi * 0.45  // Pointing at the limit
    let needleLength = 25 * scale
    let needleEnd = CGPoint(
        x: centerX + cos(needleAngle) * needleLength,
        y: centerY + sin(needleAngle) * needleLength
    )

    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(3 * scale)
    context.move(to: CGPoint(x: centerX, y: centerY))
    context.addLine(to: needleEnd)
    context.strokePath()

    // Center dot
    context.setFillColor(NSColor.white.cgColor)
    context.fillEllipse(in: CGRect(x: centerX - 4 * scale, y: centerY - 4 * scale, width: 8 * scale, height: 8 * scale))

    // Draw limit line (barrier)
    let limitAngle = CGFloat.pi * 0.4
    let limitInner = radius - 12 * scale
    let limitOuter = radius + 12 * scale

    context.setStrokeColor(NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0).cgColor)
    context.setLineWidth(3 * scale)
    context.move(to: CGPoint(x: centerX + cos(limitAngle) * limitInner, y: centerY + sin(limitAngle) * limitInner))
    context.addLine(to: CGPoint(x: centerX + cos(limitAngle) * limitOuter, y: centerY + sin(limitAngle) * limitOuter))
    context.strokePath()

    // Draw "LIMIT" text or down arrow at bottom
    let arrowY = centerY - 22 * scale
    context.setFillColor(NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0).cgColor)
    context.move(to: CGPoint(x: centerX, y: arrowY - 8 * scale))
    context.addLine(to: CGPoint(x: centerX - 6 * scale, y: arrowY))
    context.addLine(to: CGPoint(x: centerX + 6 * scale, y: arrowY))
    context.closePath()
    context.fillPath()

    image.unlockFocus()

    // Save at 1x
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let filename = size == 1024 ? "icon_512x512@2x.png" : (size >= 32 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size).png")
        try! pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))

        // Also save @2x versions for smaller sizes
        if size <= 512 && size >= 32 {
            let filename2x = "icon_\(size/2)x\(size/2)@2x.png"
            if size/2 >= 16 {
                try? pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename2x)"))
            }
        }
    }
}

print("Created iconset. Converting to icns...")

// Convert to icns using iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath]
try! process.run()
process.waitUntilExit()

// Clean up iconset
try? FileManager.default.removeItem(atPath: iconsetPath)

print("Done! Created NetLimiter.icns")
