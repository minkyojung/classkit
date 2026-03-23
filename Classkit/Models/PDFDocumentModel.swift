import Foundation
import SwiftData

@Model
final class PDFDocumentModel {
    var id: UUID
    var title: String
    @Attribute(.externalStorage) var fileData: Data
    var pageCount: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var annotations: [PDFPageAnnotation]

    @Relationship(inverse: \Classroom.documents)
    var classroom: Classroom?

    init(title: String, fileData: Data, pageCount: Int) {
        self.id = UUID()
        self.title = title
        self.fileData = fileData
        self.pageCount = pageCount
        self.annotations = []
        self.createdAt = Date()
    }
}

@Model
final class PDFPageAnnotation {
    var id: UUID
    var pageIndex: Int
    @Attribute(.externalStorage) var drawingData: Data
    var updatedAt: Date

    @Relationship(inverse: \PDFDocumentModel.annotations)
    var document: PDFDocumentModel?

    init(pageIndex: Int, drawingData: Data = Data()) {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.drawingData = drawingData
        self.updatedAt = Date()
    }
}
