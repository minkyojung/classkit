import SwiftUI

struct ClassroomDetailView: View {
    let classroom: Classroom

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                studentInfoCard
                scheduleCard
                lessonsCard
            }
            .padding()
        }
        .navigationTitle(classroom.studentName)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Student Info Card

    private var studentInfoCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: classroom.colorHex) ?? .blue)
                        .frame(width: 56, height: 56)
                        .overlay {
                            Text(String(classroom.studentName.prefix(1)))
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(classroom.studentName)
                            .font(.title3.bold())
                        HStack(spacing: 8) {
                            Text(classroom.studentGrade)
                            if let school = classroom.studentSchool, !school.isEmpty {
                                Text("·")
                                Text(school)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if let subject = classroom.subject {
                    Divider()
                    Label(subject.name, systemImage: "book.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !classroom.memo.isEmpty {
                    Divider()
                    Text(classroom.memo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("학생 정보", systemImage: "person.fill")
        }
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        GroupBox {
            HStack {
                if !classroom.scheduleDay.isEmpty {
                    Label(classroom.scheduleDay, systemImage: "calendar")
                }
                if !classroom.scheduleTime.isEmpty {
                    Label(classroom.scheduleTime, systemImage: "clock")
                }
                Spacer()
            }
            .font(.subheadline)
        } label: {
            Label("수업 일정", systemImage: "clock.fill")
        }
    }

    // MARK: - Lessons Card

    private var lessonsCard: some View {
        GroupBox {
            if classroom.lessons.isEmpty {
                ContentUnavailableView(
                    "아직 수업 기록이 없습니다",
                    systemImage: "doc.text",
                    description: Text("수업을 시작하면 여기에 기록됩니다")
                )
                .frame(minHeight: 120)
            } else {
                ForEach(classroom.lessons) { lesson in
                    LessonRowView(lesson: lesson)
                }
            }
        } label: {
            Label("수업 기록", systemImage: "list.bullet.clipboard.fill")
        }
    }
}

// MARK: - Lesson Row

struct LessonRowView: View {
    let lesson: Lesson

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.subheadline.weight(.medium))
                Text(lesson.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch lesson.status {
        case .scheduled: "예정"
        case .inProgress: "진행 중"
        case .completed: "완료"
        }
    }

    private var statusColor: Color {
        switch lesson.status {
        case .scheduled: .orange
        case .inProgress: .blue
        case .completed: .green
        }
    }
}
