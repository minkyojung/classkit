import Foundation
import SwiftData

enum QuestionFormat: String, Codable, CaseIterable {
    case multipleChoice   // 객관식 (5지선다)
    case shortAnswer      // 단답형
    case fillInBlank      // 빈칸 채우기
    case trueFalse        // O/X
    case ordering         // 순서 배열
    case matching         // 연결하기
    case essay            // 서술형 (수동 채점)

    var displayName: String {
        switch self {
        case .multipleChoice: "객관식"
        case .shortAnswer: "단답형"
        case .fillInBlank: "빈칸 채우기"
        case .trueFalse: "O/X"
        case .ordering: "순서 배열"
        case .matching: "연결하기"
        case .essay: "서술형"
        }
    }

    var isAutoGradable: Bool {
        switch self {
        case .multipleChoice, .shortAnswer, .fillInBlank, .trueFalse, .ordering, .matching:
            return true
        case .essay:
            return false
        }
    }
}

@Model
final class ExamQuestion {
    var id: UUID
    var orderIndex: Int
    var format: QuestionFormat
    var points: Int

    // Question content
    var questionText: String
    var passage: String? // 지문 (독해용)
    @Attribute(.externalStorage) var questionImageData: Data? // 이미지 첨부 (스캔 문제 등)

    // Answer options (객관식/연결/순서용, JSON array of strings)
    var optionsJSON: String?

    // Correct answer
    var correctAnswer: String // 객관식: "1"~"5", 단답: 답, O/X: "O"/"X"
    var acceptableAnswers: String? // 정답으로 인정할 대안들 (comma separated)

    // Explanation
    var explanation: String?

    // Source tracking
    var sourceType: String? // "manual", "ai", "ocr", "import"

    @Relationship(inverse: \ExamPaper.questions)
    var examPaper: ExamPaper?

    var createdAt: Date

    init(
        orderIndex: Int,
        format: QuestionFormat,
        questionText: String,
        correctAnswer: String,
        points: Int = 1
    ) {
        self.id = UUID()
        self.orderIndex = orderIndex
        self.format = format
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.points = points
        self.createdAt = Date()
    }

    // MARK: - Options Helper

    var options: [String] {
        get {
            guard let json = optionsJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                optionsJSON = json
            }
        }
    }

    // MARK: - Grading

    func isCorrect(answer: String) -> Bool {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed == correctAnswer.lowercased() { return true }

        if let acceptable = acceptableAnswers {
            let alternatives = acceptable.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces).lowercased()
            }
            return alternatives.contains(trimmed)
        }
        return false
    }
}
