import Foundation
import SwiftData

@Model
final class ScannedProblem {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var recognizedText: String
    var title: String
    var createdAt: Date

    @Relationship(inverse: \Classroom.scannedProblems)
    var classroom: Classroom?

    init(imageData: Data, recognizedText: String, title: String = "") {
        self.id = UUID()
        self.imageData = imageData
        self.recognizedText = recognizedText
        self.title = title
        self.createdAt = Date()
    }
}
