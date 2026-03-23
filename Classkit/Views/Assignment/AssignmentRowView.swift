import SwiftUI

struct AssignmentRowView: View {
    let assignment: Assignment

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(.subheadline.weight(.medium))

                if let dueDate = assignment.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(dueDate, style: .relative)
                            .font(.caption)
                    }
                    .foregroundStyle(isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var isOverdue: Bool {
        guard let dueDate = assignment.dueDate else { return false }
        return dueDate < Date() && assignment.status == .assigned
    }

    private var statusIcon: some View {
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(statusColor)
            .frame(width: 28)
    }

    private var iconName: String {
        switch assignment.status {
        case .assigned: "circle"
        case .submitted: "circle.inset.filled"
        case .reviewed: "checkmark.circle.fill"
        }
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
        switch assignment.status {
        case .assigned: "미제출"
        case .submitted: "제출완료"
        case .reviewed: "첨삭완료"
        }
    }

    private var statusColor: Color {
        switch assignment.status {
        case .assigned: .orange
        case .submitted: .blue
        case .reviewed: .green
        }
    }
}
