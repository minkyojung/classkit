import Foundation
import SwiftData

enum LessonStatus: String, Codable {
    case scheduled
    case inProgress
    case completed
}

@Model
final class Lesson {
    var id: UUID
    var date: Date
    var title: String
    var status: LessonStatus
    var summary: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var notes: [LessonNote]

    @Relationship(inverse: \Classroom.lessons)
    var classroom: Classroom?

    init(
        date: Date,
        title: String,
        status: LessonStatus = .scheduled,
        summary: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.status = status
        self.summary = summary
        self.notes = []
        self.createdAt = Date()
    }
}
