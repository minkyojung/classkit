import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct ClassroomDetailView: View {
    let classroomDTO: ClassroomDTO
    var apiService: APIService

    @Environment(\.modelContext) private var modelContext
    @State private var lessons: [LessonDTO] = []
    @State private var assignments: [AssignmentDTO] = []
    @State private var isLoading = false

    // Local SwiftData lesson for canvas (bridge until full migration)
    @State private var activeLocalLesson: Lesson?
    @State private var newLessonTitle = ""
    @State private var showNewLessonAlert = false
    @State private var showCreateAssignment = false
    @State private var showPDFImporter = false
    @State private var showScanner = false
    @State private var activePDFDocument: PDFDocumentModel?

    private var studentColor: Color {
        Color(hex: classroomDTO.colorHex) ?? .blue
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroProfileCard
                startLessonButton
                lessonsSection
                assignmentsSection
                inviteCodeSection
            }
            .padding()
        }
        .navigationTitle(classroomDTO.studentName)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $activeLocalLesson) { lesson in
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
            CreateAssignmentSheetAPI(
                classroomId: classroomDTO.id,
                apiService: apiService
            ) {
                Task { await loadAssignments() }
            }
        }
        .alert("새 수업", isPresented: $showNewLessonAlert) {
            TextField("수업 제목 (예: 3단원 이차방정식)", text: $newLessonTitle)
            Button("시작") { startNewLesson() }
            Button("취소", role: .cancel) { newLessonTitle = "" }
        } message: {
            Text("수업 제목을 입력하세요")
        }
        .task {
            await loadLessons()
            await loadAssignments()
        }
    }

    // MARK: - Hero Profile Card

    private var heroProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(studentColor.gradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: studentColor.opacity(0.3), radius: 8, y: 4)
                    .overlay {
                        Text(String(classroomDTO.studentName.prefix(1)))
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(classroomDTO.studentName)
                        .font(.title2.bold())

                    Text(classroomDTO.studentGrade)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            let hasSchedule = !(classroomDTO.scheduleDay ?? "").isEmpty || !(classroomDTO.scheduleTime ?? "").isEmpty
            let hasSubject = !(classroomDTO.subjectName ?? "").isEmpty

            if hasSubject || hasSchedule {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let subject = classroomDTO.subjectName, !subject.isEmpty {
                            TagChip(icon: "book.fill", text: subject, color: .blue)
                        }
                        if let day = classroomDTO.scheduleDay, !day.isEmpty {
                            TagChip(icon: "calendar", text: day, color: .orange)
                        }
                        if let time = classroomDTO.scheduleTime, !time.isEmpty {
                            TagChip(icon: "clock", text: time, color: .purple)
                        }
                    }
                }
            }

            if let memo = classroomDTO.memo, !memo.isEmpty {
                Text(memo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
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

    // MARK: - Invite Code

    private var inviteCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "초대 코드", icon: "person.badge.plus")

            if let code = classroomDTO.inviteCode {
                HStack {
                    Text(code)
                        .font(.title2.monospaced().bold())
                        .foregroundStyle(studentColor)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Label("복사", systemImage: "doc.on.doc")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                }

                Text("학생에게 이 코드를 공유하면 교실에 참여할 수 있습니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
                .padding(.vertical, 16)
                .background(Color.accentColor.gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .accentColor.opacity(0.25), radius: 8, y: 4)
        }
    }

    private func startNewLesson() {
        let title = newLessonTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        // Create in Supabase
        let lessonDTO = LessonDTO(
            id: UUID(),
            classroomId: classroomDTO.id,
            title: title,
            status: "inProgress"
        )

        // Also create local SwiftData lesson for canvas
        let localLesson = Lesson(date: Date(), title: title, status: .inProgress)
        modelContext.insert(localLesson)

        Task {
            do {
                _ = try await apiService.createLesson(lessonDTO)
                await loadLessons()
            } catch {
                // Lesson still works locally even if API fails
            }
        }

        newLessonTitle = ""
        activeLocalLesson = localLesson
    }

    // MARK: - Lessons Section

    private func loadLessons() async {
        do {
            lessons = try await apiService.fetchLessons(classroomId: classroomDTO.id)
        } catch {
            // Keep showing existing data
        }
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "수업 기록", icon: "list.bullet.clipboard.fill")

            if lessons.isEmpty {
                EmptyStateCard(
                    icon: "doc.text",
                    message: "수업을 시작하면 여기에 기록됩니다"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        LessonDTORowView(lesson: lesson, isLast: index == lessons.count - 1)
                            .padding(.vertical, 6)
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

    // MARK: - Assignments Section

    private func loadAssignments() async {
        do {
            assignments = try await apiService.fetchAssignments(classroomId: classroomDTO.id)
        } catch {
            // Keep showing existing data
        }
    }

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "과제", icon: "tray.full.fill")
                Spacer()
                let pending = assignments.filter { $0.status == "assigned" }.count
                if pending > 0 {
                    Text("\(pending)개 미제출")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange, in: Capsule())
                }
            }

            if assignments.isEmpty {
                Button {
                    showCreateAssignment = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                        Text("과제 출제하기")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 0) {
                    ForEach(assignments) { assignment in
                        AssignmentDTORowView(assignment: assignment)
                            .padding(.vertical, 6)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    Button {
                        showCreateAssignment = true
                    } label: {
                        Label("과제 추가", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.accentColor)
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

    // MARK: - PDF Import (still local)

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
        modelContext.insert(document)
        activePDFDocument = document
    }
}

// MARK: - Lesson DTO Row

struct LessonDTORowView: View {
    let lesson: LessonDTO
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.subheadline.weight(.medium))
                if let date = lesson.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch lesson.status {
        case "inProgress": "진행 중"
        case "completed": "완료"
        default: "예정"
        }
    }

    private var statusColor: Color {
        switch lesson.status {
        case "inProgress": .blue
        case "completed": .green
        default: .orange
        }
    }
}

// MARK: - Assignment DTO Row

struct AssignmentDTORowView: View {
    let assignment: AssignmentDTO

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.title)
                    .font(.subheadline.weight(.medium))
                if let dueDate = assignment.dueDate {
                    Text("마감: \(dueDate, format: .dateTime.month().day())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch assignment.status {
        case "submitted": "제출완료"
        case "reviewed": "첨삭완료"
        default: "미제출"
        }
    }

    private var statusColor: Color {
        switch assignment.status {
        case "submitted": .blue
        case "reviewed": .green
        default: .orange
        }
    }
}

// MARK: - Create Assignment (API version)

struct CreateAssignmentSheetAPI: View {
    let classroomId: UUID
    var apiService: APIService
    var onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var instruction = ""
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("과제 정보") {
                    TextField("과제 제목", text: $title)
                    TextField("과제 설명 (선택)", text: $instruction, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("마감일 설정", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("마감일", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("과제 출제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("출제") { createAssignment() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func createAssignment() {
        isCreating = true
        let dto = AssignmentDTO(
            id: UUID(),
            classroomId: classroomId,
            title: title.trimmingCharacters(in: .whitespaces),
            instruction: instruction.trimmingCharacters(in: .whitespaces).isEmpty ? nil : instruction.trimmingCharacters(in: .whitespaces),
            dueDate: hasDueDate ? dueDate : nil,
            status: "assigned"
        )

        Task {
            do {
                _ = try await apiService.createAssignment(dto)
                onCreated()
                dismiss()
            } catch {
                errorMessage = "과제 생성 실패: \(error.localizedDescription)"
                isCreating = false
            }
        }
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

struct TagChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1), in: Capsule())
    }
}

struct EmptyStateCard: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.quaternary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

struct MaterialActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        }
    }
}
