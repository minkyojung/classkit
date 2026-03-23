import Foundation
import SwiftData

enum OverlayType: String, Codable {
    case text
    case image
    case shape
}

enum ShapeType: String, Codable {
    case line
    case rectangle
    case circle
    case arrow
}

@Model
final class CanvasOverlay {
    var id: UUID
    var type: OverlayType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double

    // Text properties
    var text: String?
    var fontSize: Double?

    // Image properties
    @Attribute(.externalStorage) var imageData: Data?

    // Shape properties
    var shapeType: ShapeType?
    var strokeColorHex: String?
    var strokeWidth: Double?
    var fillColorHex: String?

    var createdAt: Date

    @Relationship(inverse: \LessonNote.overlays)
    var note: LessonNote?

    @Relationship(inverse: \PDFPageAnnotation.overlays)
    var pdfAnnotation: PDFPageAnnotation?

    init(
        type: OverlayType,
        x: Double,
        y: Double,
        width: Double = 200,
        height: Double = 100
    ) {
        self.id = UUID()
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = 0
        self.createdAt = Date()
    }

    static func textOverlay(x: Double, y: Double, text: String = "") -> CanvasOverlay {
        let overlay = CanvasOverlay(type: .text, x: x, y: y, width: 200, height: 44)
        overlay.text = text
        overlay.fontSize = 16
        return overlay
    }

    static func imageOverlay(x: Double, y: Double, imageData: Data, width: Double, height: Double) -> CanvasOverlay {
        let overlay = CanvasOverlay(type: .image, x: x, y: y, width: width, height: height)
        overlay.imageData = imageData
        return overlay
    }

    static func shapeOverlay(x: Double, y: Double, shapeType: ShapeType, width: Double = 150, height: Double = 150) -> CanvasOverlay {
        let overlay = CanvasOverlay(type: .shape, x: x, y: y, width: width, height: height)
        overlay.shapeType = shapeType
        overlay.strokeColorHex = "#000000"
        overlay.strokeWidth = 2
        return overlay
    }
}
