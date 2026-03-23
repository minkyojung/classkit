import SwiftUI
import SwiftData

struct AssignmentDetailView: View {
    @Bindable var assignment: Assignment
    @Environment(\.modelContext) private var modelContext

    @State private var showSubmissionCanvas = false
    @State private var showFeedbackCanvas = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                infoCard
                statusCard
                feedbackCard
                actionSection
            }
            .padding()
        }
        .navigationTitle(assignment.title)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showSubmissionCanvas) {
            SubmissionCanvasView(assignment: assignment)
        }
        .fullScreenCover(isPresented: $showFeedbackCanvas) {
            FeedbackCanvasView(assignment: assignment)
        }
    }

    // MARK: - Feedback Card

    @ViewBuilder
    private var feedbackCard: some View {
        if assignment.status == .reviewed, let submission = assignment.submission {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    if let score = submission.score {
                        HStack {
                            Label("점수", systemImage: "star.fill")
                            Spacer()
                            Text("\(score)점")
                                .font(.title3.bold())
                                .foregroundStyle(.orange)
                        }
                    }

                    if let comment = submission.comment, !comment.isEmpty {
                        Divider()
                        Text(comment)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let reviewedAt = submission.reviewedAt {
                        Divider()
                        HStack {
                            Label("첨삭일", systemImage: "calendar")
                            Spacer()
                            Text(reviewedAt, format: .dateTime.month().day().hour().minute())
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            } label: {
                Label("첨삭 결과", systemImage: "checkmark.seal.fill")
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                if !assignment.instruction.isEmpty {
                    Text(assignment.instruction)
                        .font(.body)
                }

                if let dueDate = assignment.dueDate {
                    Divider()
                    HStack {
                        Label("마감일", systemImage: "calendar.badge.clock")
                        Spacer()
                        Text(dueDate, format: .dateTime.month().day().hour().minute())
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                    .font(.subheadline)
                }

                Divider()
                HStack {
                    Label("출제일", systemImage: "calendar")
                    Spacer()
                    Text(assignment.createdAt, format: .dateTime.month().day())
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        } label: {
            Label("과제 정보", systemImage: "info.circle.fill")
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        GroupBox {
            HStack {
                statusIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(statusDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        } label: {
            Label("제출 현황", systemImage: "tray.fill")
        }
    }

    private var statusIcon: some View {
        Image(systemName: statusIconName)
            .font(.largeTitle)
            .foregroundStyle(statusColor)
    }

    private var statusIconName: String {
        switch assignment.status {
        case .assigned: "circle.dashed"
        case .submitted: "checkmark.circle.fill"
        case .reviewed: "checkmark.seal.fill"
        }
    }

    private var statusTitle: String {
        switch assignment.status {
        case .assigned: "미제출"
        case .submitted: "제출 완료"
        case .reviewed: "첨삭 완료"
        }
    }

    private var statusDescription: String {
        switch assignment.status {
        case .assigned:
            if let dueDate = assignment.dueDate {
                return isOverdue ? "마감일이 지났습니다" : "마감까지 \(dueDate.formatted(.relative(presentation: .numeric)))"
            }
            return "아직 제출하지 않았습니다"
        case .submitted:
            if let submission = assignment.submission {
                return "제출일: \(submission.submittedAt.formatted(.dateTime.month().day().hour().minute()))"
            }
            return "제출되었습니다"
        case .reviewed:
            return "선생님이 첨삭을 완료했습니다"
        }
    }

    private var statusColor: Color {
        switch assignment.status {
        case .assigned: .orange
        case .submitted: .blue
        case .reviewed: .green
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = assignment.dueDate else { return false }
        return dueDate < Date() && assignment.status == .assigned
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 12) {
            switch assignment.status {
            case .assigned:
                Button {
                    showSubmissionCanvas = true
                } label: {
                    Label("풀이 작성", systemImage: "pencil.tip.crop.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            case .submitted:
                Button {
                    showFeedbackCanvas = true
                } label: {
                    Label("첨삭하기", systemImage: "pencil.and.scribble")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showSubmissionCanvas = true
                } label: {
                    Label("제출 내용 보기", systemImage: "eye")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            case .reviewed:
                Button {
                    showFeedbackCanvas = true
                } label: {
                    Label("첨삭 결과 보기", systemImage: "eye")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showFeedbackCanvas = true
                } label: {
                    Label("첨삭 수정", systemImage: "pencil.and.scribble")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.15))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
