import SwiftUI

struct ClassroomRow: View {
    let classroom: Classroom

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: classroom.colorHex) ?? .blue)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(classroom.studentName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(classroom.studentName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    if let subject = classroom.subject {
                        Text(subject.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(classroom.studentGrade)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !classroom.scheduleDay.isEmpty {
                Text(classroom.scheduleDay)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
