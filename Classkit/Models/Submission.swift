import Foundation
import SwiftData

@Model
final class Submission {
    var id: UUID
    var drawingData: Data
    var submittedAt: Date

    @Relationship(inverse: \Assignment.submission)
    var assignment: Assignment?

    init(drawingData: Data = Data()) {
        self.id = UUID()
        self.drawingData = drawingData
        self.submittedAt = Date()
    }
}
