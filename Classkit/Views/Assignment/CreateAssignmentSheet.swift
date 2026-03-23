import SwiftUI
import SwiftData

struct CreateAssignmentSheet: View {
    let classroom: Classroom
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var instruction = ""
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("과제 정보") {
                    TextField("과제 제목", text: $title)
                    TextField("설명 (선택)", text: $instruction, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("마감일") {
                    Toggle("마감일 설정", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "마감일",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("과제 출제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("출제") { createAssignment() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func createAssignment() {
        let assignment = Assignment(
            title: title.trimmingCharacters(in: .whitespaces),
            instruction: instruction.trimmingCharacters(in: .whitespaces),
            dueDate: hasDueDate ? dueDate : nil
        )
        assignment.classroom = classroom
        modelContext.insert(assignment)
        dismiss()
    }
}
