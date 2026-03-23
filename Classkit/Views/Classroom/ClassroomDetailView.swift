import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct ClassroomDetailView: View {
    @Bindable var classroom: Classroom
    @Environment(\.modelContext) private var modelContext

    @State private var activeLesson: Lesson?
    @State private var newLessonTitle = ""
    @State private var showNewLessonAlert = false
    @State private var showPDFImporter = false
    @State private var activePDFDocument: PDFDocumentModel?
    @State private var showCreateAssignment = false
    @State private var showScanner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                studentInfoCard
                scheduleCard
                startLessonButton
                lessonsCard
                assignmentsCard
                ScoreChartView(classroom: classroom)
                scannedProblemsCard
                documentsCard
            }
            .padding()
        }
        .navigationTitle(classroom.studentName)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $activeLesson) { lesson in
            CanvasContainerView(lesson: lesson)
        }
        .fullScreenCover(item: $activePDFDocument) { doc in
            PDFCanvasView(document: doc)
        }
        .fileImporter(
            isPresented: $showPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handlePDFImport(result)
        }
        .sheet(isPresented: $showCreateAssignment) {
            CreateAssignmentSheet(classroom: classroom)
        }
        .sheet(isPresented: $showScanner) {
            ScannerView(classroom: classroom)
        }
        .alert("새 수업", isPresented: $showNewLessonAlert) {
            TextField("수업 제목 (예: 3단원 이차방정식)", text: $newLessonTitle)
            Button("시작") { startNewLesson() }
            Button("취소", role: .cancel) { newLessonTitle = "" }
        } message: {
            Text("수업 제목을 입력하세요")
        }
    }

    // MARK: - Start Lesson

    private var startLessonButton: some View {
        Button {
            showNewLessonAlert = true
        } label: {
            Label("수업 시작", systemImage: "pencil.tip.crop.circle")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func startNewLesson() {
        let title = newLessonTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        let lesson = Lesson(date: Date(), title: title, status: .inProgress)
        lesson.classroom = classroom
        modelContext.insert(lesson)

        newLessonTitle = ""
        activeLesson = lesson
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

    // MARK: - Assignments Card

    private var assignmentsCard: some View {
        GroupBox {
            VStack(spacing: 8) {
                if classroom.assignments.isEmpty {
                    Button {
                        showCreateAssignment = true
                    } label: {
                        Label("과제 출제하기", systemImage: "plus.app")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                } else {
                    ForEach(classroom.assignments.sorted { $0.createdAt > $1.createdAt }) { assignment in
                        NavigationLink {
                            AssignmentDetailView(assignment: assignment)
                        } label: {
                            AssignmentRowView(assignment: assignment)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    Button {
                        showCreateAssignment = true
                    } label: {
                        Label("과제 추가", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }
        } label: {
            HStack {
                Label("과제", systemImage: "tray.full.fill")
                Spacer()
                if !classroom.assignments.isEmpty {
                    let pending = classroom.assignments.filter { $0.status == .assigned }.count
                    if pending > 0 {
                        Text("\(pending)개 미제출")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Scanned Problems Card

    private var scannedProblemsCard: some View {
        GroupBox {
            VStack(spacing: 8) {
                if classroom.scannedProblems.isEmpty {
                    Button {
                        showScanner = true
                    } label: {
                        Label("문제 스캔하기", systemImage: "doc.text.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                } else {
                    ForEach(classroom.scannedProblems.sorted { $0.createdAt > $1.createdAt }) { problem in
                        HStack {
                            if let uiImage = UIImage(data: problem.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(problem.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Text(problem.recognizedText.prefix(50))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(problem.createdAt, format: .dateTime.month().day())
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }

                    Divider()

                    Button {
                        showScanner = true
                    } label: {
                        Label("스캔 추가", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }
        } label: {
            Label("스캔 문제", systemImage: "doc.text.viewfinder")
        }
    }

    // MARK: - Documents Card

    private var documentsCard: some View {
        GroupBox {
            VStack(spacing: 8) {
                if classroom.documents.isEmpty {
                    Button {
                        showPDFImporter = true
                    } label: {
                        Label("PDF 교재 추가", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                } else {
                    ForEach(classroom.documents.sorted { $0.createdAt > $1.createdAt }) { doc in
                        Button {
                            activePDFDocument = doc

                        } label: {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.title)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(doc.pageCount)페이지")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    Button {
                        showPDFImporter = true
                    } label: {
                        Label("PDF 추가", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }
        } label: {
            Label("교재", systemImage: "books.vertical.fill")
        }
    }

    // MARK: - PDF Import

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else { return }

        let pageCount: Int
        if let pdfDoc = PDFKit.PDFDocument(data: data) {
            pageCount = pdfDoc.pageCount
        } else {
            return
        }

        let title = url.deletingPathExtension().lastPathComponent
        let document = PDFDocumentModel(title: title, fileData: data, pageCount: pageCount)
        document.classroom = classroom
        modelContext.insert(document)

        activePDFDocument = document
        // activePDFDocument triggers fullScreenCover
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
                ForEach(classroom.lessons.sorted { $0.date > $1.date }) { lesson in
                    Button {
                        activeLesson = lesson
                    } label: {
                        LessonRowView(lesson: lesson)
                    }
                    .buttonStyle(.plain)
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
