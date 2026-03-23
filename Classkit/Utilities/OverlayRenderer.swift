import UIKit

/// Renders CanvasOverlay items into a CGContext for PDF export.
enum OverlayRenderer {

    static func render(_ overlays: [CanvasOverlay], in context: CGContext, bounds: CGRect) {
        for overlay in overlays {
            context.saveGState()

            let overlayRect = CGRect(
                x: overlay.x - overlay.width / 2,
                y: overlay.y - overlay.height / 2,
                width: overlay.width,
                height: overlay.height
            )

            // Apply rotation around overlay center
            if overlay.rotation != 0 {
                context.translateBy(x: overlay.x, y: overlay.y)
                context.rotate(by: overlay.rotation * .pi / 180)
                context.translateBy(x: -overlay.x, y: -overlay.y)
            }

            switch overlay.type {
            case .text:
                renderText(overlay, in: overlayRect)
            case .image:
                renderImage(overlay, in: overlayRect)
            case .shape:
                renderShape(overlay, in: overlayRect, context: context)
            }

            context.restoreGState()
        }
    }

    // MARK: - Text

    private static func renderText(_ overlay: CanvasOverlay, in rect: CGRect) {
        guard let text = overlay.text, !text.isEmpty else { return }

        let fontSize = overlay.fontSize ?? 16
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]

        let nsString = text as NSString
        nsString.draw(in: rect.insetBy(dx: 8, dy: 8), withAttributes: attributes)
    }

    // MARK: - Image

    private static func renderImage(_ overlay: CanvasOverlay, in rect: CGRect) {
        guard let data = overlay.imageData,
              let image = UIImage(data: data) else { return }
        image.draw(in: rect)
    }

    // MARK: - Shape

    private static func renderShape(_ overlay: CanvasOverlay, in rect: CGRect, context: CGContext) {
        let colorHex = overlay.strokeColorHex ?? "#000000"
        let strokeColor = UIColor(hex: colorHex)
        let lineWidth = overlay.strokeWidth ?? 2

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(lineWidth)

        switch overlay.shapeType {
        case .rectangle:
            context.stroke(rect)
        case .circle:
            context.strokeEllipse(in: rect)
        case .line:
            context.move(to: CGPoint(x: rect.minX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            context.strokePath()
        case .arrow:
            let midY = rect.midY
            // Line
            context.move(to: CGPoint(x: rect.minX, y: midY))
            context.addLine(to: CGPoint(x: rect.maxX, y: midY))
            // Arrowhead
            context.move(to: CGPoint(x: rect.maxX - 12, y: midY - 8))
            context.addLine(to: CGPoint(x: rect.maxX, y: midY))
            context.addLine(to: CGPoint(x: rect.maxX - 12, y: midY + 8))
            context.strokePath()
        case nil:
            break
        }
    }
}

// MARK: - UIColor hex helper

private extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
