import SwiftUI
import SwiftData

struct StudentMainView: View {
    @Query(sort: \Classroom.createdAt, order: .reverse)
    private var classrooms: [Classroom]

    var onSwitchRole: () -> Void

    @State private var selectedClassroom: Classroom?

    var body: some View {
        NavigationSplitView {
            List(classrooms, selection: $selectedClassroom) { classroom in
                StudentClassroomRow(classroom: classroom)
                    .tag(classroom)
            }
            .navigationTitle("내 수업")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        onSwitchRole()
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .accessibilityLabel("역할 전환")
                }
            }
        } detail: {
            if let classroom = selectedClassroom {
                StudentClassroomDetailView(classroom: classroom)
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.quaternary)
                    VStack(spacing: 8) {
                        Text("수업을 선택해주세요")
                            .font(.title3.weight(.semibold))
                        Text("왼쪽 목록에서 수업을 선택하면\n과제와 수업 정보를 확인할 수 있어요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

// MARK: - Student Classroom Row

private struct StudentClassroomRow: View {
    let classroom: Classroom

    private var studentColor: Color {
        Color(hex: classroom.colorHex) ?? .blue
    }

    private var pendingCount: Int {
        classroom.assignments.filter { $0.status == .assigned }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(studentColor.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(classroom.subject?.name ?? "수업")
                    .font(.subheadline.weight(.medium))
                Text(classroom.studentName + " 선생님")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
