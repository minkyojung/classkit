import SwiftUI
import SwiftData
import PencilKit

struct CanvasContainerView: View {
    @Bindable var lesson: Lesson
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentPageIndex = 0
    @State private var selectedBackground: NoteBackgroundType = .blank
    @State private var showBackgroundPicker = false
    @State private var showCompleteConfirm = false
    @State private var showShareSheet = false
    @State private var exportedPDFData: Data?
    @State private var zoomScale: CGFloat = 1.0

    private var currentNote: LessonNote? {
        lesson.notes.first { $0.pageIndex == currentPageIndex }
    }

    private var sortedNotes: [LessonNote] {
        lesson.notes.sorted { $0.pageIndex < $1.pageIndex }
    }

    private var pageCount: Int {
        max(1, (lesson.notes.map(\.pageIndex).max() ?? 0) + 1)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        // Background pattern
                        NoteBackgroundView(
                            backgroundType: currentNote?.backgroundType ?? selectedBackground,
                            size: canvasSize(for: geometry.size)
                        )

                        // PencilKit canvas overlay — pencil only, finger scrolls
                        CanvasView(
                            drawingData: drawingBinding,
                            backgroundColor: .clear,
                            drawingPolicy: .pencilOnly
                        )
                        .frame(
                            width: canvasSize(for: geometry.size).width,
                            height: canvasSize(for: geometry.size).height
                        )
                    }
                    .scaleEffect(zoomScale)
                    .frame(
                        width: canvasSize(for: geometry.size).width * zoomScale,
                        height: canvasSize(for: geometry.size).height * zoomScale
                    )
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = min(max(value, 0.5), 3.0)
                        }
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        saveCurrentPage()
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    backgroundPickerButton
                    zoomControls
                    shareButton
                    completeButton
                    pageControls
                }

                ToolbarItem(placement: .bottomBar) {
                    pageThumbnailStrip
                }
            }
            .popover(isPresented: $showBackgroundPicker) {
                backgroundPickerContent
            }
            .alert("수업 완료", isPresented: $showCompleteConfirm) {
                Button("완료", role: .destructive) { completeLesson() }
                Button("취소", role: .cancel) { }
            } message: {
                Text("수업을 완료하시겠습니까? 노트가 저장됩니다.")
            }
        }
    }

    // MARK: - Canvas Size

    private func canvasSize(for viewSize: CGSize) -> CGSize {
        // A4-ish aspect ratio, wider than view for scrollable area
        CGSize(width: max(viewSize.width, 768), height: max(viewSize.height, 1024))
    }

    // MARK: - Drawing Binding

    private func noteForCurrentPage() -> LessonNote? {
        lesson.notes.first { $0.pageIndex == currentPageIndex }
    }

    private var drawingBinding: Binding<Data> {
        Binding(
            get: {
                noteForCurrentPage()?.drawingData ?? Data()
            },
            set: { newData in
                if let note = noteForCurrentPage() {
                    note.drawingData = newData
                    note.updatedAt = Date()
                } else {
                    let note = LessonNote(
                        pageIndex: currentPageIndex,
                        drawingData: newData,
                        backgroundType: selectedBackground
                    )
                    note.lesson = lesson
                    lesson.notes.append(note)
                    modelContext.insert(note)
                }
            }
        )
    }

    // MARK: - Zoom Controls

    private var zoomControls: some View {
        HStack(spacing: 2) {
            Button {
                withAnimation { zoomScale = max(zoomScale - 0.25, 0.5) }
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }

            Button {
                withAnimation { zoomScale = 1.0 }
            } label: {
                Text("\(Int(zoomScale * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 40)
            }

            Button {
                withAnimation { zoomScale = min(zoomScale + 0.25, 3.0) }
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
        }
    }

    // MARK: - Background Picker

    private var backgroundPickerButton: some View {
        Button {
            showBackgroundPicker = true
        } label: {
            Image(systemName: "square.grid.3x3")
        }
        .accessibilityLabel("배경 선택")
    }

    private var backgroundPickerContent: some View {
        VStack(spacing: 16) {
            Text("배경 선택")
                .font(.headline)
                .padding(.top)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(NoteBackgroundType.allCases, id: \.self) { bg in
                    Button {
                        selectedBackground = bg
                        if let note = currentNote {
                            note.backgroundType = bg
                        }
                        showBackgroundPicker = false
                    } label: {
                        VStack(spacing: 6) {
                            NoteBackgroundView(backgroundType: bg, size: CGSize(width: 80, height: 60))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(bg == selectedBackground ? Color.accentColor : Color.clear, lineWidth: 2)
                                )

                            Text(bg.displayName)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 220)
    }

    // MARK: - Page Controls

    private var pageControls: some View {
        HStack(spacing: 4) {
            Button {
                guard currentPageIndex > 0 else { return }
                saveCurrentPage()
                currentPageIndex -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPageIndex == 0)

            Text("\(currentPageIndex + 1) / \(pageCount)")
                .font(.caption.monospacedDigit())
                .frame(minWidth: 50)

            Button {
                saveCurrentPage()
                currentPageIndex += 1
            } label: {
                Image(systemName: "chevron.right")
            }

            Button {
                saveCurrentPage()
                currentPageIndex = pageCount
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("페이지 추가")
        }
    }

    // MARK: - Thumbnail Strip

    private var pageThumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Button {
                        saveCurrentPage()
                        currentPageIndex = index
                    } label: {
                        thumbnailView(for: index)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func thumbnailView(for index: Int) -> some View {
        let isSelected = index == currentPageIndex

        return Group {
            if let note = lesson.notes.first(where: { $0.pageIndex == index }),
               let drawing = try? PKDrawing(data: note.drawingData),
               !drawing.strokes.isEmpty {
                // Real thumbnail from drawing
                let image = drawing.image(from: CGRect(x: 0, y: 0, width: 768, height: 1024), scale: 0.1)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(width: 44, height: 58)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 0.5)
                    )
            } else {
                // Empty page placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.white)
                    .frame(width: 44, height: 58)
                    .overlay(
                        Text("\(index + 1)")
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 0.5)
                    )
            }
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            showCompleteConfirm = true
        } label: {
            Image(systemName: "checkmark.circle")
        }
        .disabled(lesson.status == .completed)
        .accessibilityLabel("수업 완료")
    }

    private func completeLesson() {
        saveCurrentPage()
        lesson.status = .completed
        dismiss()
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            saveCurrentPage()
            exportedPDFData = exportNotesAsPDF()
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("PDF로 공유")
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedPDFData {
                ShareSheet(activityItems: [data])
            }
        }
    }

    private func exportNotesAsPDF() -> Data {
        let pageSize = CGRect(x: 0, y: 0, width: 768, height: 1024)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)

        return renderer.pdfData { context in
            for note in sortedNotes {
                context.beginPage()

                // Draw background
                UIColor.white.setFill()
                UIRectFill(pageSize)

                // Draw note content
                if let drawing = try? PKDrawing(data: note.drawingData) {
                    let image = drawing.image(from: pageSize, scale: 2.0)
                    image.draw(in: pageSize)
                }
            }

            // If no notes, create blank page
            if sortedNotes.isEmpty {
                context.beginPage()
                UIColor.white.setFill()
                UIRectFill(pageSize)
            }
        }
    }

    // MARK: - Save

    private func saveCurrentPage() {
        if let note = currentNote {
            note.updatedAt = Date()
        }
    }
}

// MARK: - NoteBackgroundType Extension

extension NoteBackgroundType {
    var displayName: String {
        switch self {
        case .blank: "빈 페이지"
        case .lined: "줄노트"
        case .grid: "모눈"
        case .dotted: "점"
        }
    }
}
