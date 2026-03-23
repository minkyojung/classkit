import Foundation
import SwiftData

@Model
final class Classroom {
    var id: UUID
    var studentName: String
    var studentSchool: String?
    var studentGrade: String
    var parentContact: String?
    var scheduleDay: String
    var scheduleTime: String
    var memo: String
    var colorHex: String
    var createdAt: Date

    var subject: Subject?

    @Relationship(deleteRule: .cascade)
    var lessons: [Lesson]

    @Relationship(deleteRule: .cascade)
    var documents: [PDFDocumentModel]

    @Relationship(inverse: \Teacher.classrooms)
    var teacher: Teacher?

    init(
        studentName: String,
        studentGrade: String,
        subject: Subject? = nil,
        scheduleDay: String = "",
        scheduleTime: String = "",
        memo: String = "",
        colorHex: String = "#34C759"
    ) {
        self.id = UUID()
        self.studentName = studentName
        self.studentGrade = studentGrade
        self.subject = subject
        self.scheduleDay = scheduleDay
        self.scheduleTime = scheduleTime
        self.memo = memo
        self.colorHex = colorHex
        self.lessons = []
        self.documents = []
        self.createdAt = Date()
    }
}
