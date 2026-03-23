import Foundation
import SwiftData

enum ExamSubject: String, Codable, CaseIterable {
    case english
    case japanese
    case chinese
    case korean // 한국어 (외국인 대상)
    case koreanLiterature // 국어

    var displayName: String {
        switch self {
        case .english: "영어"
        case .japanese: "일본어"
        case .chinese: "중국어"
        case .korean: "한국어"
        case .koreanLiterature: "국어"
        }
    }
}

enum ExamType: String, Codable, CaseIterable {
    case vocabulary  // 단어 테스트
    case grammar     // 문법 테스트
    case writing     // 작문 테스트
    case reading     // 독해 테스트
    case mixed       // 종합

    var displayName: String {
        switch self {
        case .vocabulary: "단어"
        case .grammar: "문법"
        case .writing: "작문"
        case .reading: "독해"
        case .mixed: "종합"
        }
    }
}

enum ExamDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var displayName: String {
        switch self {
        case .easy: "하"
        case .medium: "중"
        case .hard: "상"
        }
    }
}

@Model
final class ExamPaper {
    var id: UUID
    var title: String
    var subject: ExamSubject
    var examType: ExamType
    var difficulty: ExamDifficulty
    var timeLimit: Int? // minutes, nil = no limit
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var questions: [ExamQuestion]

    @Relationship(inverse: \Classroom.examPapers)
    var classroom: Classroom?

    init(
        title: String,
        subject: ExamSubject,
        examType: ExamType,
        difficulty: ExamDifficulty = .medium,
        timeLimit: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.examType = examType
        self.difficulty = difficulty
        self.timeLimit = timeLimit
        self.questions = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
