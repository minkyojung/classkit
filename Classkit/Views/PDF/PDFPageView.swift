import SwiftUI
import PDFKit

struct PDFPageView: View {
    let pdfData: Data
    let pageIndex: Int

    var body: some View {
        if let image = renderPageImage() {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Color.white
                .overlay {
                    Text("페이지를 불러올 수 없습니다")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func renderPageImage() -> UIImage? {
        guard let document = PDFKit.PDFDocument(data: pdfData),
              let page = document.page(at: pageIndex) else { return nil }

        let bounds = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: bounds.size)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(bounds)

            let cgContext = context.cgContext
            cgContext.saveGState()
            // PDF coordinate system: origin at bottom-left, flip for UIKit
            cgContext.translateBy(x: 0, y: bounds.height)
            cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: cgContext)
            cgContext.restoreGState()
        }
    }
}

// MARK: - PDF Page Size Helper

enum PDFPageHelper {
    static func pageSize(from data: Data, pageIndex: Int) -> CGSize? {
        guard let document = PDFKit.PDFDocument(data: data),
              let page = document.page(at: pageIndex) else { return nil }
        return page.bounds(for: .mediaBox).size
    }
}
