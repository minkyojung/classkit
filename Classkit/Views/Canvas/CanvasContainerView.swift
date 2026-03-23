import SwiftUI
import SwiftData

struct CanvasContainerView: View {
    @Bindable var lesson: Lesson
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentPageIndex = 0
    @State private var selectedBackground: NoteBackgroundType = .blank
    @State private var showBackgroundPicker = false

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
                ZStack {
                    // Background pattern
                    NoteBackgroundView(
                        backgroundType: currentNote?.backgroundType ?? selectedBackground,
                        size: geometry.size
                    )

                    // PencilKit canvas overlay
                    CanvasView(
                        drawingData: drawingBinding,
                        backgroundColor: .clear
                    )
                }
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
                    pageControls
                }

                ToolbarItem(placement: .bottomBar) {
                    pageThumbnailStrip
                }
            }
            .popover(isPresented: $showBackgroundPicker) {
                backgroundPickerContent
            }
        }
    }

    // MARK: - Drawing Binding

    private var drawingBinding: Binding<Data> {
        Binding(
            get: {
                currentNote?.drawingData ?? Data()
            },
            set: { newData in
                if let note = currentNote {
                    note.drawingData = newData
                    note.updatedAt = Date()
                } else {
                    let note = LessonNote(
                        pageIndex: currentPageIndex,
                        drawingData: newData,
                        backgroundType: selectedBackground
                    )
                    note.lesson = lesson
                    modelContext.insert(note)
                }
            }
        )
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
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == currentPageIndex ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            .frame(width: 40, height: 30)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(index == currentPageIndex ? .primary : .secondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(index == currentPageIndex ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
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
