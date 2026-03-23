import SwiftUI
import SwiftData
import PDFKit
import PencilKit
import PhotosUI

struct PDFCanvasView: View {
    @Bindable var document: PDFDocumentModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentPageIndex = 0
    @State private var showShareSheet = false
    @State private var exportedPDFData: Data?
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var canvasCoordinator: CanvasView.Coordinator?

    // Overlay state
    @State private var selectedOverlayID: UUID?
    @State private var showShapePicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    private var currentAnnotation: PDFPageAnnotation? {
        document.annotations.first { $0.pageIndex == currentPageIndex }
    }

    /// Actual PDF page size in points
    private var pageSize: CGSize {
        PDFPageHelper.pageSize(from: document.fileData, pageIndex: currentPageIndex)
            ?? CGSize(width: 612, height: 792) // US Letter fallback
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    pdfCanvasContent
                        .scaleEffect(zoomScale)
                        .frame(
                            width: pageSize.width * zoomScale,
                            height: pageSize.height * zoomScale
                        )
                }
                .gesture(zoomGesture)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        saveCurrentAnnotation()
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    overlayToolbarButton
                    undoRedoButtons
                    zoomControls
                    pageControls
                    shareButton
                }

                ToolbarItem(placement: .bottomBar) {
                    pageThumbnailStrip
                }
            }
            .popover(isPresented: $showShapePicker) {
                shapePickerContent
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task { await loadPhoto(from: newItem) }
            }
        }
    }

    // MARK: - PDF + Canvas Content

    private var pdfCanvasContent: some View {
        ZStack {
            // PDF page rendered as image at exact mediaBox size
            PDFPageView(
                pdfData: document.fileData,
                pageIndex: currentPageIndex
            )
            .frame(width: pageSize.width, height: pageSize.height)

            // PencilKit overlay at the same exact size
            CanvasView(
                drawingData: annotationBinding,
                backgroundColor: .clear,
                drawingPolicy: .pencilOnly,
                onCoordinatorReady: { coordinator in
                    canvasCoordinator = coordinator
                }
            )
            .frame(width: pageSize.width, height: pageSize.height)

            // Overlays (text, image, shape) on PDF
            ForEach(currentOverlays) { overlay in
                OverlayItemView(
                    overlay: overlay,
                    isSelected: selectedOverlayID == overlay.id,
                    onSelect: { selectedOverlayID = overlay.id },
                    onDelete: { deleteOverlay(overlay) }
                )
            }
        }
        .onTapGesture {
            selectedOverlayID = nil
        }
    }

    // MARK: - Undo / Redo

    private var undoRedoButtons: some View {
        HStack(spacing: 4) {
            Button {
                canvasCoordinator?.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .accessibilityLabel("실행 취소")

            Button {
                canvasCoordinator?.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .accessibilityLabel("다시 실행")
        }
    }

    // MARK: - Overlays

    private var currentOverlays: [CanvasOverlay] {
        currentAnnotation?.overlays ?? []
    }

    private func ensureCurrentAnnotation() -> PDFPageAnnotation {
        if let annotation = annotationForCurrentPage() {
            return annotation
        }
        let annotation = PDFPageAnnotation(pageIndex: currentPageIndex)
        annotation.document = document
        document.annotations.append(annotation)
        modelContext.insert(annotation)
        return annotation
    }

    private func addTextOverlay() {
        let annotation = ensureCurrentAnnotation()
        let centerX = pageSize.width / 2
        let centerY = pageSize.height / 2
        let overlay = CanvasOverlay.textOverlay(x: centerX, y: centerY)
        overlay.pdfAnnotation = annotation
        annotation.overlays.append(overlay)
        modelContext.insert(overlay)
        selectedOverlayID = overlay.id
    }

    private func addShapeOverlay(_ shapeType: ShapeType) {
        let annotation = ensureCurrentAnnotation()
        let centerX = pageSize.width / 2
        let centerY = pageSize.height / 2
        let overlay = CanvasOverlay.shapeOverlay(x: centerX, y: centerY, shapeType: shapeType)
        overlay.pdfAnnotation = annotation
        annotation.overlays.append(overlay)
        modelContext.insert(overlay)
        selectedOverlayID = overlay.id
        showShapePicker = false
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        let maxDimension: CGFloat = min(pageSize.width * 0.6, 400)
        let scale = min(maxDimension / uiImage.size.width, maxDimension / uiImage.size.height, 1.0)
        let width = uiImage.size.width * scale
        let height = uiImage.size.height * scale

        let annotation = ensureCurrentAnnotation()
        let overlay = CanvasOverlay.imageOverlay(
            x: pageSize.width / 2,
            y: pageSize.height / 2,
            imageData: data,
            width: width,
            height: height
        )
        overlay.pdfAnnotation = annotation
        annotation.overlays.append(overlay)
        modelContext.insert(overlay)
        selectedOverlayID = overlay.id
        selectedPhoto = nil
    }

    private func deleteOverlay(_ overlay: CanvasOverlay) {
        if selectedOverlayID == overlay.id {
            selectedOverlayID = nil
        }
        if let annotation = overlay.pdfAnnotation {
            annotation.overlays.removeAll { $0.id == overlay.id }
        }
        modelContext.delete(overlay)
    }

    // MARK: - Overlay Toolbar

    private var overlayToolbarButton: some View {
        Menu {
            Button {
                addTextOverlay()
            } label: {
                Label("텍스트", systemImage: "textformat")
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("이미지", systemImage: "photo")
            }

            Button {
                showShapePicker = true
            } label: {
                Label("도형", systemImage: "square.on.circle")
            }
        } label: {
            Image(systemName: "plus.rectangle.on.rectangle")
        }
        .accessibilityLabel("오버레이 추가")
    }

    private var shapePickerContent: some View {
        VStack(spacing: 16) {
            Text("도형 선택")
                .font(.headline)
                .padding(.top)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                shapeButton(.rectangle, icon: "rectangle", label: "사각형")
                shapeButton(.circle, icon: "circle", label: "원")
                shapeButton(.line, icon: "line.diagonal", label: "선")
                shapeButton(.arrow, icon: "arrow.right", label: "화살표")
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 200)
    }

    private func shapeButton(_ type: ShapeType, icon: String, label: String) -> some View {
        Button {
            addShapeOverlay(type)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Zoom

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoomScale = min(max(lastZoomScale * value, 0.5), 4.0)
            }
            .onEnded { value in
                zoomScale = min(max(lastZoomScale * value, 0.5), 4.0)
                lastZoomScale = zoomScale
            }
    }

    private var zoomControls: some View {
        HStack(spacing: 2) {
            Button {
                withAnimation { adjustZoom(by: -0.25) }
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }

            Button {
                withAnimation {
                    zoomScale = 1.0
                    lastZoomScale = 1.0
                }
            } label: {
                Text("\(Int(zoomScale * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 40)
            }

            Button {
                withAnimation { adjustZoom(by: 0.25) }
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
        }
    }

    private func adjustZoom(by delta: CGFloat) {
        zoomScale = min(max(zoomScale + delta, 0.5), 4.0)
        lastZoomScale = zoomScale
    }

    // MARK: - Annotation Binding

    private func annotationForCurrentPage() -> PDFPageAnnotation? {
        document.annotations.first { $0.pageIndex == currentPageIndex }
    }

    private var annotationBinding: Binding<Data> {
        Binding(
            get: {
                annotationForCurrentPage()?.drawingData ?? Data()
            },
            set: { newData in
                if let annotation = annotationForCurrentPage() {
                    annotation.drawingData = newData
                    annotation.updatedAt = Date()
                } else {
                    let annotation = PDFPageAnnotation(
                        pageIndex: currentPageIndex,
                        drawingData: newData
                    )
                    annotation.document = document
                    document.annotations.append(annotation)
                    modelContext.insert(annotation)
                }
            }
        )
    }

    private func saveCurrentAnnotation() {
        if let annotation = annotationForCurrentPage() {
            annotation.updatedAt = Date()
        }
    }

    // MARK: - Page Controls

    private var pageControls: some View {
        HStack(spacing: 4) {
            Button {
                guard currentPageIndex > 0 else { return }
                saveCurrentAnnotation()
                currentPageIndex -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPageIndex == 0)

            Text("\(currentPageIndex + 1) / \(document.pageCount)")
                .font(.caption.monospacedDigit())
                .frame(minWidth: 50)

            Button {
                guard currentPageIndex < document.pageCount - 1 else { return }
                saveCurrentAnnotation()
                currentPageIndex += 1
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPageIndex >= document.pageCount - 1)
        }
    }

    // MARK: - Share

    private var shareButton: some View {
        Button {
            saveCurrentAnnotation()
            exportedPDFData = exportAnnotatedPDF()
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedPDFData {
                ShareSheet(activityItems: [data])
            }
        }
    }

    private func exportAnnotatedPDF() -> Data {
        guard let pdfDocument = PDFKit.PDFDocument(data: document.fileData) else {
            return document.fileData
        }

        let firstPageBounds = pdfDocument.page(at: 0)?.bounds(for: .mediaBox)
            ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: firstPageBounds)

        return renderer.pdfData { context in
            for pageIndex in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                let pageBounds = page.bounds(for: .mediaBox)
                context.beginPage(withBounds: pageBounds, pageInfo: [:])

                let cgContext = context.cgContext
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: pageBounds.height)
                cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: cgContext)
                cgContext.restoreGState()

                if let annotation = document.annotations.first(where: { $0.pageIndex == pageIndex }) {
                    // Draw PencilKit annotation at high resolution
                    if let drawing = try? PKDrawing(data: annotation.drawingData) {
                        let image = drawing.image(from: pageBounds, scale: 4.0)
                        image.draw(in: pageBounds)
                    }

                    // Draw overlays (text, image, shape)
                    OverlayRenderer.render(annotation.overlays, in: cgContext, bounds: pageBounds)
                }
            }
        }
    }

    // MARK: - Thumbnail Strip

    private var pageThumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<document.pageCount, id: \.self) { index in
                    Button {
                        saveCurrentAnnotation()
                        currentPageIndex = index
                    } label: {
                        pdfThumbnail(for: index)
                            .frame(width: 40, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
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

    private func pdfThumbnail(for pageIndex: Int) -> some View {
        Group {
            if let pdfDoc = PDFKit.PDFDocument(data: document.fileData),
               let page = pdfDoc.page(at: pageIndex) {
                let thumbnail = page.thumbnail(of: CGSize(width: 40, height: 56), for: .mediaBox)
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay(
                        Text("\(pageIndex + 1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }
}
