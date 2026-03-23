import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var gradeLevel: String
    var colorHex: String

    @Relationship(inverse: \Teacher.subjects)
    var teacher: Teacher?

    init(name: String, gradeLevel: String, colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.gradeLevel = gradeLevel
        self.colorHex = colorHex
    }
}
