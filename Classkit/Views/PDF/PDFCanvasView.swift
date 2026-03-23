import SwiftUI
import SwiftData
import PDFKit
import PencilKit

struct PDFCanvasView: View {
    @Bindable var document: PDFDocumentModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentPageIndex = 0
    @State private var showShareSheet = false
    @State private var exportedPDFData: Data?
    @State private var zoomScale: CGFloat = 1.0

    private var currentAnnotation: PDFPageAnnotation? {
        document.annotations.first { $0.pageIndex == currentPageIndex }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        // PDF page as background
                        PDFPageView(
                            pdfData: document.fileData,
                            pageIndex: currentPageIndex
                        )

                        // PencilKit overlay for annotation
                        CanvasView(
                            drawingData: annotationBinding,
                            backgroundColor: .clear,
                            drawingPolicy: .pencilOnly
                        )
                    }
                    .scaleEffect(zoomScale)
                    .frame(
                        width: geometry.size.width * zoomScale,
                        height: geometry.size.height * zoomScale
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
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    pageControls
                    shareButton
                }

                ToolbarItem(placement: .bottomBar) {
                    pageThumbnailStrip
                }
            }
        }
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

    // MARK: - Page Controls

    private var pageControls: some View {
        HStack(spacing: 4) {
            Button {
                guard currentPageIndex > 0 else { return }
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

        let renderer = UIGraphicsPDFRenderer(
            bounds: pdfDocument.page(at: 0)?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        )

        return renderer.pdfData { context in
            for pageIndex in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                let pageBounds = page.bounds(for: .mediaBox)
                context.beginPage(withBounds: pageBounds, pageInfo: [:])

                let cgContext = context.cgContext
                cgContext.saveGState()

                // Flip coordinate system for PDF rendering
                cgContext.translateBy(x: 0, y: pageBounds.height)
                cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: cgContext)

                cgContext.restoreGState()

                // Draw annotation overlay
                if let annotation = document.annotations.first(where: { $0.pageIndex == pageIndex }),
                   let drawing = try? PKDrawing(data: annotation.drawingData) {
                    let image = drawing.image(from: pageBounds, scale: 2.0)
                    image.draw(in: pageBounds)
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
