import Foundation
import SwiftData

enum AssignmentStatus: String, Codable {
    case assigned
    case submitted
    case reviewed
}

@Model
final class Assignment {
    var id: UUID
    var title: String
    var instruction: String
    var dueDate: Date?
    var status: AssignmentStatus
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var attachments: [AssignmentAttachment]

    @Relationship(deleteRule: .cascade)
    var submission: Submission?

    @Relationship(inverse: \Classroom.assignments)
    var classroom: Classroom?

    init(
        title: String,
        instruction: String = "",
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.instruction = instruction
        self.dueDate = dueDate
        self.status = .assigned
        self.attachments = []
        self.createdAt = Date()
    }
}

@Model
final class AssignmentAttachment {
    var id: UUID
    var fileName: String
    var fileData: Data
    var fileType: String

    @Relationship(inverse: \Assignment.attachments)
    var assignment: Assignment?

    init(fileName: String, fileData: Data, fileType: String) {
        self.id = UUID()
        self.fileName = fileName
        self.fileData = fileData
        self.fileType = fileType
    }
}
