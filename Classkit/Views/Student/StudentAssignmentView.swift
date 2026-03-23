import SwiftUI
import SwiftData
import PencilKit

struct StudentAssignmentView: View {
    @Bindable var assignment: Assignment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showSubmitConfirm = false
    @State private var viewMode: ViewMode = .assignment

    enum ViewMode: String, CaseIterable {
        case assignment = "과제"
        case submit = "풀이"
        case feedback = "첨삭"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode picker
                Picker("보기", selection: $viewMode) {
                    ForEach(availableModes, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                switch viewMode {
                case .assignment:
                    assignmentContent
                case .submit:
                    submitContent
                case .feedback:
                    feedbackContent
                }
            }
            .navigationTitle(assignment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }

                if viewMode == .submit && assignment.status == .assigned {
                    ToolbarItem(placement: .primaryAction) {
                        Button("제출") {
                            showSubmitConfirm = true
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("과제 제출", isPresented: $showSubmitConfirm) {
                Button("제출", role: .destructive) { submitAssignment() }
                Button("취소", role: .cancel) { }
            } message: {
                Text("과제를 제출하시겠습니까?")
            }
        }
    }

    private var availableModes: [ViewMode] {
        var modes: [ViewMode] = [.assignment, .submit]
        if assignment.status == .reviewed {
            modes.append(.feedback)
        }
        return modes
    }

    // MARK: - Assignment Content (read-only info)

    private var assignmentContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status card
                HStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundStyle(statusColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusText)
                            .font(.headline)
                        if let due = assignment.dueDate {
                            let isOverdue = due < Date() && assignment.status == .assigned
                            Text("마감: \(due, format: .dateTime.month().day().hour().minute())")
                                .font(.caption)
                                .foregroundStyle(isOverdue ? .red : .secondary)
                        }
                    }
                    Spacer()

                    if assignment.status == .reviewed, let score = assignment.submission?.score {
                        VStack(spacing: 2) {
                            Text("\(score)")
                                .font(.title.bold())
                                .foregroundStyle(.blue)
                            Text("점")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(statusColor.opacity(0.08))
                }

                // Instructions
                if !assignment.instruction.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("과제 설명")
                            .font(.subheadline.weight(.semibold))
                        Text(assignment.instruction)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }

                // Teacher comment
                if let comment = assignment.submission?.comment, !comment.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("선생님 코멘트", systemImage: "text.bubble")
                            .font(.subheadline.weight(.semibold))
                        Text(comment)
                            .font(.body)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.06))
                    }
                }

                // Action hint
                if assignment.status == .assigned {
                    Button {
                        viewMode = .submit
                    } label: {
                        Label("풀이 작성하기", systemImage: "pencil.tip.crop.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Submit Content (PencilKit canvas)

    private var submitContent: some View {
        VStack(spacing: 0) {
            if assignment.status == .assigned {
                // Editable canvas for submission
                CanvasView(
                    drawingData: submissionDrawingBinding,
                    backgroundColor: .white,
                    drawingPolicy: .pencilOnly
                )
            } else {
                // Read-only view of submitted work
                if let submission = assignment.submission,
                   let drawing = try? PKDrawing(data: submission.drawingData) {
                    ScrollView {
                        let image = drawing.image(
                            from: CGRect(x: 0, y: 0, width: 768, height: 1024),
                            scale: 2.0
                        )
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                            .padding()
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.title)
                            .foregroundStyle(.quaternary)
                        Text("제출한 풀이가 없습니다")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    // MARK: - Feedback Content

    private var feedbackContent: some View {
        VStack(spacing: 0) {
            if let submission = assignment.submission,
               let feedbackData = submission.feedbackDrawingData,
               let drawing = try? PKDrawing(data: feedbackData) {
                ScrollView {
                    ZStack {
                        // Student's original work
                        if let studentDrawing = try? PKDrawing(data: submission.drawingData) {
                            let studentImage = studentDrawing.image(
                                from: CGRect(x: 0, y: 0, width: 768, height: 1024),
                                scale: 2.0
                            )
                            Image(uiImage: studentImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }

                        // Teacher's feedback overlay
                        let feedbackImage = drawing.image(
                            from: CGRect(x: 0, y: 0, width: 768, height: 1024),
                            scale: 2.0
                        )
                        Image(uiImage: feedbackImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .background(Color.white)
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "pencil.slash")
                        .font(.title)
                        .foregroundStyle(.quaternary)
                    Text("첨삭 결과가 아직 없습니다")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Submission Binding

    private var submissionDrawingBinding: Binding<Data> {
        Binding(
            get: {
                assignment.submission?.drawingData ?? Data()
            },
            set: { newData in
                if let submission = assignment.submission {
                    submission.drawingData = newData
                } else {
                    let submission = Submission(drawingData: newData)
                    submission.assignment = assignment
                    assignment.submission = submission
                    modelContext.insert(submission)
                }
            }
        )
    }

    private func submitAssignment() {
        if assignment.submission == nil {
            let submission = Submission()
            submission.assignment = assignment
            assignment.submission = submission
            modelContext.insert(submission)
        }
        assignment.submission?.submittedAt = Date()
        assignment.status = .submitted
        viewMode = .assignment
    }

    // MARK: - Status Helpers

    private var statusText: String {
        switch assignment.status {
        case .assigned: "미제출"
        case .submitted: "제출 완료"
        case .reviewed: "첨삭 완료"
        }
    }

    private var statusColor: Color {
        switch assignment.status {
        case .assigned: .orange
        case .submitted: .blue
        case .reviewed: .green
        }
    }

    private var statusIcon: String {
        switch assignment.status {
        case .assigned: "exclamationmark.circle.fill"
        case .submitted: "checkmark.circle.fill"
        case .reviewed: "pencil.circle.fill"
        }
    }
}
