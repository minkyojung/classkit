import SwiftUI
import PDFKit

struct PDFPageView: UIViewRepresentable {
    let pdfData: Data
    let pageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.isUserInteractionEnabled = false
        pdfView.backgroundColor = .white
        pdfView.pageShadowsEnabled = false

        if let document = PDFKit.PDFDocument(data: pdfData) {
            pdfView.document = document
            if let page = document.page(at: pageIndex) {
                pdfView.go(to: page)
            }
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = pdfView.document,
           let page = document.page(at: pageIndex) {
            pdfView.go(to: page)
        }
    }
}
