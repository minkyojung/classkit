import Foundation
import PostgREST

// MARK: - Codable DTOs (Supabase ↔ App)

struct ClassroomDTO: Codable, Identifiable {
    let id: UUID
    var teacherId: UUID
    var studentName: String
    var studentGrade: String
    var subjectName: String?
    var scheduleDay: String?
    var scheduleTime: String?
    var memo: String?
    var colorHex: String
    var inviteCode: String?
    var studentId: UUID?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case studentName = "student_name"
        case studentGrade = "student_grade"
        case subjectName = "subject_name"
        case scheduleDay = "schedule_day"
        case scheduleTime = "schedule_time"
        case memo
        case colorHex = "color_hex"
        case inviteCode = "invite_code"
        case studentId = "student_id"
        case createdAt = "created_at"
    }
}

struct LessonDTO: Codable, Identifiable {
    let id: UUID
    var classroomId: UUID
    var title: String
    var status: String
    var date: Date?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case classroomId = "classroom_id"
        case title, status, date
        case createdAt = "created_at"
    }
}

struct LessonNoteDTO: Codable, Identifiable {
    let id: UUID
    var lessonId: UUID
    var pageIndex: Int
    var drawingDataUrl: String?
    var backgroundType: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case lessonId = "lesson_id"
        case pageIndex = "page_index"
        case drawingDataUrl = "drawing_data_url"
        case backgroundType = "background_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AssignmentDTO: Codable, Identifiable {
    let id: UUID
    var classroomId: UUID
    var title: String
    var instruction: String?
    var dueDate: Date?
    var status: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case classroomId = "classroom_id"
        case title, instruction, status
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}

struct SubmissionDTO: Codable, Identifiable {
    let id: UUID
    var assignmentId: UUID
    var drawingDataUrl: String?
    var feedbackDrawingUrl: String?
    var score: Int?
    var comment: String?
    var submittedAt: Date?
    var reviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case assignmentId = "assignment_id"
        case drawingDataUrl = "drawing_data_url"
        case feedbackDrawingUrl = "feedback_drawing_url"
        case score, comment
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
    }
}

// MARK: - API Service

@Observable
final class APIService {
    private let db = SupabaseConfig.database

    // MARK: - Classrooms

    func fetchClassrooms(teacherId: UUID) async throws -> [ClassroomDTO] {
        try await db.from("classrooms")
            .select()
            .eq("teacher_id", value: teacherId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchStudentClassrooms(studentId: UUID) async throws -> [ClassroomDTO] {
        try await db.from("classrooms")
            .select()
            .eq("student_id", value: studentId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createClassroom(_ classroom: ClassroomDTO) async throws -> ClassroomDTO {
        try await db.from("classrooms")
            .insert(classroom)
            .select()
            .single()
            .execute()
            .value
    }

    func updateClassroom(_ classroom: ClassroomDTO) async throws {
        try await db.from("classrooms")
            .update(classroom)
            .eq("id", value: classroom.id.uuidString)
            .execute()
    }

    func deleteClassroom(id: UUID) async throws {
        try await db.from("classrooms")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func joinClassroom(inviteCode: String, studentId: UUID) async throws -> ClassroomDTO {
        try await db.from("classrooms")
            .update(["student_id": studentId.uuidString])
            .eq("invite_code", value: inviteCode)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Lessons

    func fetchLessons(classroomId: UUID) async throws -> [LessonDTO] {
        try await db.from("lessons")
            .select()
            .eq("classroom_id", value: classroomId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
    }

    func createLesson(_ lesson: LessonDTO) async throws -> LessonDTO {
        try await db.from("lessons")
            .insert(lesson)
            .select()
            .single()
            .execute()
            .value
    }

    func updateLesson(_ lesson: LessonDTO) async throws {
        try await db.from("lessons")
            .update(lesson)
            .eq("id", value: lesson.id.uuidString)
            .execute()
    }

    func deleteLesson(id: UUID) async throws {
        try await db.from("lessons")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Lesson Notes

    func fetchNotes(lessonId: UUID) async throws -> [LessonNoteDTO] {
        try await db.from("lesson_notes")
            .select()
            .eq("lesson_id", value: lessonId.uuidString)
            .order("page_index")
            .execute()
            .value
    }

    func upsertNote(_ note: LessonNoteDTO) async throws -> LessonNoteDTO {
        try await db.from("lesson_notes")
            .upsert(note)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Assignments

    func fetchAssignments(classroomId: UUID) async throws -> [AssignmentDTO] {
        try await db.from("assignments")
            .select()
            .eq("classroom_id", value: classroomId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createAssignment(_ assignment: AssignmentDTO) async throws -> AssignmentDTO {
        try await db.from("assignments")
            .insert(assignment)
            .select()
            .single()
            .execute()
            .value
    }

    func updateAssignment(_ assignment: AssignmentDTO) async throws {
        try await db.from("assignments")
            .update(assignment)
            .eq("id", value: assignment.id.uuidString)
            .execute()
    }

    func deleteAssignment(id: UUID) async throws {
        try await db.from("assignments")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Submissions

    func fetchSubmission(assignmentId: UUID) async throws -> SubmissionDTO? {
        let results: [SubmissionDTO] = try await db.from("submissions")
            .select()
            .eq("assignment_id", value: assignmentId.uuidString)
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func upsertSubmission(_ submission: SubmissionDTO) async throws -> SubmissionDTO {
        try await db.from("submissions")
            .upsert(submission)
            .select()
            .single()
            .execute()
            .value
    }
}
