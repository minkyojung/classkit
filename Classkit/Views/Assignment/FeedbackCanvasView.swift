import SwiftUI
import SwiftData
import PencilKit

struct FeedbackCanvasView: View {
    @Bindable var assignment: Assignment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackDrawingData: Data
    @State private var showOriginalOnly = false
    @State private var score: String
    @State private var comment: String
    @State private var showScoreSheet = false

    init(assignment: Assignment) {
        self.assignment = assignment
        _feedbackDrawingData = State(initialValue: assignment.submission?.feedbackDrawingData ?? Data())
        _score = State(initialValue: assignment.submission?.score.map { String($0) } ?? "")
        _comment = State(initialValue: assignment.submission?.comment ?? "")
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // White background
                    Color.white

                    // Student's original drawing (non-editable)
                    if let submission = assignment.submission {
                        StudentDrawingView(drawingData: submission.drawingData)
                    }

                    // Teacher's feedback overlay (red pen)
                    if !showOriginalOnly {
                        CanvasView(
                            drawingData: $feedbackDrawingData,
                            backgroundColor: .clear,
                            drawingPolicy: .pencilOnly
                        )
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle("첨삭 - \(assignment.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Toggle(isOn: $showOriginalOnly) {
                        Image(systemName: showOriginalOnly ? "eye" : "eye.slash")
                    }
                    .help(showOriginalOnly ? "첨삭 보기" : "원본만 보기")

                    Button {
                        showScoreSheet = true
                    } label: {
                        Image(systemName: "star.circle")
                    }

                    Button("완료") { saveFeedback() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showScoreSheet) {
                scoreInputSheet
            }
        }
    }

    // MARK: - Score Input Sheet

    private var scoreInputSheet: some View {
        NavigationStack {
            Form {
                Section("점수") {
                    TextField("점수 (0~100)", text: $score)
                        .keyboardType(.numberPad)
                    if let parsed = Int(score), (parsed < 0 || parsed > 100) {
                        Text("0~100 사이의 점수를 입력하세요")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("코멘트") {
                    TextField("코멘트 (선택)", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("평가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") { showScoreSheet = false }
                        .disabled(isScoreInvalid)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var isScoreInvalid: Bool {
        guard !score.isEmpty else { return false }
        guard let parsed = Int(score) else { return true }
        return parsed < 0 || parsed > 100
    }

    // MARK: - Save

    private func saveFeedback() {
        guard let submission = assignment.submission else { return }

        submission.feedbackDrawingData = feedbackDrawingData
        submission.score = Int(score)
        submission.comment = comment.trimmingCharacters(in: .whitespaces)
        submission.reviewedAt = Date()
        assignment.status = .reviewed

        dismiss()
    }
}

// MARK: - Student Drawing View (Read-only)

struct StudentDrawingView: UIViewRepresentable {
    let drawingData: Data

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.isUserInteractionEnabled = false
        canvas.backgroundColor = .clear
        canvas.isOpaque = false

        if let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }
    }
}
