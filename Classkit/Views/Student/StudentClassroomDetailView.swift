import SwiftUI
import SwiftData

struct StudentClassroomDetailView: View {
    @Bindable var classroom: Classroom

    @State private var selectedAssignment: Assignment?

    private var studentColor: Color {
        Color(hex: classroom.colorHex) ?? .blue
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                classInfoCard
                assignmentsSection
                ScoreChartView(classroom: classroom)
                lessonHistorySection
            }
            .padding()
        }
        .navigationTitle(classroom.subject?.name ?? "수업")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $selectedAssignment) { assignment in
            StudentAssignmentView(assignment: assignment)
        }
    }

    // MARK: - Class Info Card

    private var classInfoCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(studentColor.gradient)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(classroom.studentName + " 선생님")
                    .font(.title3.bold())

                HStack(spacing: 6) {
                    if !classroom.scheduleDay.isEmpty {
                        Label(classroom.scheduleDay, systemImage: "calendar")
                    }
                    if !classroom.scheduleTime.isEmpty {
                        Label(classroom.scheduleTime, systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(studentColor.opacity(0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(studentColor.opacity(0.1), lineWidth: 1)
        }
    }

    // MARK: - Assignments

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("과제", systemImage: "tray.full.fill")
                    .font(.headline)
                Spacer()
                let pending = classroom.assignments.filter { $0.status == .assigned }.count
                if pending > 0 {
                    Text("\(pending)개 미제출")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange, in: Capsule())
                }
            }

            if classroom.assignments.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.quaternary)
                    Text("아직 출제된 과제가 없어요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(classroom.assignments.sorted { $0.createdAt > $1.createdAt }) { assignment in
                        Button {
                            selectedAssignment = assignment
                        } label: {
                            StudentAssignmentRow(assignment: assignment)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }

    // MARK: - Lesson History (read-only)

    private var lessonHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("수업 기록", systemImage: "list.bullet.clipboard.fill")
                .font(.headline)

            if classroom.lessons.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.quaternary)
                    Text("수업 기록이 없어요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(classroom.lessons.sorted { $0.date > $1.date }) { lesson in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(lesson.status == .completed ? Color.green : Color.blue)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title)
                                    .font(.subheadline.weight(.medium))
                                Text(lesson.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(lesson.status == .completed ? "완료" : "진행 중")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    (lesson.status == .completed ? Color.green : Color.blue).opacity(0.12)
                                )
                                .foregroundStyle(lesson.status == .completed ? .green : .blue)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }
}

// MARK: - Student Assignment Row

private struct StudentAssignmentRow: View {
    let assignment: Assignment

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: statusIcon)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    if let due = assignment.dueDate {
                        let isOverdue = due < Date() && assignment.status == .assigned
                        Text(due, format: .dateTime.month().day())
                            .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                    Text(statusText)
                        .foregroundStyle(statusColor)
                }
                .font(.caption)
            }

            Spacer()

            if assignment.status == .reviewed, let score = assignment.submission?.score {
                Text("\(score)점")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

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
        case .assigned: "exclamationmark.circle"
        case .submitted: "checkmark.circle"
        case .reviewed: "pencil.circle"
        }
    }
}
