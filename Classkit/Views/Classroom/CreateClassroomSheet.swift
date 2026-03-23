import SwiftUI
import Auth

struct CreateClassroomSheet: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    var apiService: APIService
    var onCreated: () -> Void

    @State private var studentName = ""
    @State private var studentGrade = ""
    @State private var subjectName = ""
    @State private var scheduleDay = ""
    @State private var scheduleTime = ""
    @State private var memo = ""
    @State private var selectedColorHex = "#007AFF"
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let gradeOptions = [
        "5세", "6세", "7세",
        "초1", "초2", "초3", "초4", "초5", "초6",
        "중1", "중2", "중3",
        "고1", "고2", "고3",
        "N수", "대학생", "성인"
    ]

    private let colorOptions = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30",
        "#AF52DE", "#5856D6", "#FF2D55", "#00C7BE"
    ]

    private var isValid: Bool {
        !studentName.trimmingCharacters(in: .whitespaces).isEmpty
        && !studentGrade.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("학생 정보") {
                    TextField("학생 이름", text: $studentName)
                    Picker("학년", selection: $studentGrade) {
                        Text("선택").tag("")
                        ForEach(gradeOptions, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                }

                Section("과목") {
                    TextField("과목명 (예: 수학)", text: $subjectName)
                }

                Section("수업 일정") {
                    TextField("요일 (예: 월, 수)", text: $scheduleDay)
                    TextField("시간 (예: 19:00)", text: $scheduleTime)
                }

                Section("교실 색상") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if hex == selectedColorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("메모") {
                    TextField("학생 특이사항 (선택)", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("새 교실")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("생성") { createClassroom() }
                        .disabled(!isValid || isCreating)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func createClassroom() {
        guard let userId = authManager.currentUser?.id else { return }
        isCreating = true

        let dto = ClassroomDTO(
            id: UUID(),
            teacherId: userId,
            studentName: studentName.trimmingCharacters(in: .whitespaces),
            studentGrade: studentGrade,
            subjectName: subjectName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : subjectName.trimmingCharacters(in: .whitespaces),
            scheduleDay: scheduleDay.trimmingCharacters(in: .whitespaces).isEmpty ? nil : scheduleDay.trimmingCharacters(in: .whitespaces),
            scheduleTime: scheduleTime.trimmingCharacters(in: .whitespaces).isEmpty ? nil : scheduleTime.trimmingCharacters(in: .whitespaces),
            memo: memo.trimmingCharacters(in: .whitespaces).isEmpty ? nil : memo.trimmingCharacters(in: .whitespaces),
            colorHex: selectedColorHex
        )

        Task {
            do {
                _ = try await apiService.createClassroom(dto)
                onCreated()
                dismiss()
            } catch {
                errorMessage = "교실 생성 실패: \(error.localizedDescription)"
                isCreating = false
            }
        }
    }
}
