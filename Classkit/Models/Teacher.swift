import Foundation
import SwiftData

@Model
final class Teacher {
    var id: UUID
    var appleUserID: String
    var name: String
    var profileImageData: Data?
    var bio: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var subjects: [Subject]

    @Relationship(deleteRule: .cascade)
    var classrooms: [Classroom]

    init(
        appleUserID: String,
        name: String,
        bio: String = "",
        subjects: [Subject] = [],
        classrooms: [Classroom] = []
    ) {
        self.id = UUID()
        self.appleUserID = appleUserID
        self.name = name
        self.bio = bio
        self.subjects = subjects
        self.classrooms = classrooms
        self.createdAt = Date()
    }
}
