import SwiftUI
import Charts

struct ScoreEntry: Identifiable {
    let id = UUID()
    let title: String
    let score: Int
    let date: Date
}

struct ScoreChartView: View {
    let classroom: Classroom

    private var scoreEntries: [ScoreEntry] {
        classroom.assignments
            .filter { $0.status == .reviewed }
            .compactMap { assignment in
                guard let score = assignment.submission?.score else { return nil }
                return ScoreEntry(
                    title: assignment.title,
                    score: score,
                    date: assignment.submission?.reviewedAt ?? assignment.createdAt
                )
            }
            .sorted { $0.date < $1.date }
    }

    private var averageScore: Double {
        guard !scoreEntries.isEmpty else { return 0 }
        return Double(scoreEntries.map(\.score).reduce(0, +)) / Double(scoreEntries.count)
    }

    var body: some View {
        GroupBox {
            if scoreEntries.isEmpty {
                ContentUnavailableView(
                    "아직 성적 데이터가 없습니다",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("과제를 첨삭하면 성적 추이가 표시됩니다")
                )
                .frame(minHeight: 120)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    summaryRow
                    chart
                    scoreList
                }
            }
        } label: {
            Label("성적 추이", systemImage: "chart.line.uptrend.xyaxis")
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 20) {
            StatBadge(
                title: "평균",
                value: String(format: "%.0f", averageScore),
                color: averageColor
            )
            StatBadge(
                title: "최고",
                value: "\(scoreEntries.map(\.score).max() ?? 0)",
                color: .green
            )
            StatBadge(
                title: "최저",
                value: "\(scoreEntries.map(\.score).min() ?? 0)",
                color: .orange
            )
            StatBadge(
                title: "총 과제",
                value: "\(scoreEntries.count)",
                color: .blue
            )
        }
    }

    private var averageColor: Color {
        if averageScore >= 80 { return .green }
        if averageScore >= 60 { return .orange }
        return .red
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(scoreEntries) { entry in
            LineMark(
                x: .value("날짜", entry.date),
                y: .value("점수", entry.score)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.accentColor)

            PointMark(
                x: .value("날짜", entry.date),
                y: .value("점수", entry.score)
            )
            .foregroundStyle(Color.accentColor)

            RuleMark(y: .value("평균", averageScore))
                .foregroundStyle(.secondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100])
        }
        .frame(height: 200)
    }

    // MARK: - Score List

    private var scoreList: some View {
        VStack(spacing: 0) {
            ForEach(scoreEntries.reversed()) { entry in
                HStack {
                    Text(entry.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(entry.score)점")
                        .font(.subheadline.bold())
                        .foregroundStyle(scoreColor(entry.score))
                    Text(entry.date, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.vertical, 6)

                if entry.id != scoreEntries.reversed().last?.id {
                    Divider()
                }
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
