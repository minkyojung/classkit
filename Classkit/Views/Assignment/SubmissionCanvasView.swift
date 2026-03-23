import SwiftUI
import SwiftData
import PencilKit

struct SubmissionCanvasView: View {
    @Bindable var assignment: Assignment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var drawingData: Data

    init(assignment: Assignment) {
        self.assignment = assignment
        _drawingData = State(initialValue: assignment.submission?.drawingData ?? Data())
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    NoteBackgroundView(
                        backgroundType: .lined,
                        size: geometry.size
                    )

                    CanvasView(
                        drawingData: $drawingData,
                        backgroundColor: .clear,
                        drawingPolicy: .pencilOnly
                    )
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle(assignment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("제출") { submitAssignment() }
                        .fontWeight(.semibold)
                        .disabled(drawingData.isEmpty)
                }
            }
        }
    }

    private func submitAssignment() {
        if let existing = assignment.submission {
            existing.drawingData = drawingData
            existing.submittedAt = Date()
        } else {
            let submission = Submission(drawingData: drawingData)
            submission.assignment = assignment
            modelContext.insert(submission)
        }
        assignment.status = .submitted
        dismiss()
    }
}
