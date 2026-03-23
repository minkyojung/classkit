import Foundation
import SwiftData

enum NoteBackgroundType: String, Codable, CaseIterable {
    case blank
    case lined
    case grid
    case dotted
}

@Model
final class LessonNote {
    var id: UUID
    var pageIndex: Int
    @Attribute(.externalStorage) var drawingData: Data
    var backgroundType: NoteBackgroundType
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var overlays: [CanvasOverlay]

    @Relationship(inverse: \Lesson.notes)
    var lesson: Lesson?

    init(
        pageIndex: Int,
        drawingData: Data = Data(),
        backgroundType: NoteBackgroundType = .blank
    ) {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.drawingData = drawingData
        self.backgroundType = backgroundType
        self.overlays = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
