import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var drawingData: Data
    var backgroundColor: UIColor = .clear
    var drawingPolicy: PKCanvasViewDrawingPolicy = .anyInput

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = drawingPolicy
        canvas.backgroundColor = backgroundColor
        canvas.isOpaque = false

        if let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        // Show system tool picker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        context.coordinator.toolPicker = toolPicker

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Avoid feedback loop: only update if data changed externally
        if context.coordinator.isUpdatingFromDelegate { return }

        if let drawing = try? PKDrawing(data: drawingData),
           drawing.dataRepresentation() != canvas.drawing.dataRepresentation() {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingData: $drawingData)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawingData: Data
        var toolPicker: PKToolPicker?
        var isUpdatingFromDelegate = false

        init(drawingData: Binding<Data>) {
            _drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            drawingData = canvasView.drawing.dataRepresentation()
            isUpdatingFromDelegate = false
        }
    }
}
