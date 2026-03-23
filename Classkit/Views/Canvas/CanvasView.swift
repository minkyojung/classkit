import SwiftUI
import PencilKit

enum CanvasTool: String, CaseIterable {
    case pen
    case highlighter
    case eraser
    case lasso

    var displayName: String {
        switch self {
        case .pen: "펜"
        case .highlighter: "형광펜"
        case .eraser: "지우개"
        case .lasso: "올가미"
        }
    }

    var iconName: String {
        switch self {
        case .pen: "pencil.tip"
        case .highlighter: "highlighter"
        case .eraser: "eraser"
        case .lasso: "lasso"
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var drawingData: Data
    var backgroundColor: UIColor = .clear
    var drawingPolicy: PKCanvasViewDrawingPolicy = .pencilOnly
    var currentTool: CanvasTool = .pen
    var penColor: UIColor = .black
    var penWidth: CGFloat = 3
    var isReadOnly: Bool = false

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = drawingPolicy
        canvas.backgroundColor = backgroundColor
        canvas.isOpaque = false
        canvas.isUserInteractionEnabled = !isReadOnly

        if let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        applyTool(to: canvas)

        // Show system tool picker
        if !isReadOnly {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvas)
            toolPicker.addObserver(canvas)
            canvas.becomeFirstResponder()
            context.coordinator.toolPicker = toolPicker
        }

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Skip if this update was triggered by our own delegate
        guard !context.coordinator.shouldSkipNextUpdate else {
            context.coordinator.shouldSkipNextUpdate = false
            return
        }

        if let drawing = try? PKDrawing(data: drawingData),
           drawing.dataRepresentation() != canvas.drawing.dataRepresentation() {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingData: $drawingData)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch currentTool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: penColor, width: penWidth)
        case .highlighter:
            canvas.tool = PKInkingTool(.marker, color: penColor.withAlphaComponent(0.3), width: 15)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)
        case .lasso:
            canvas.tool = PKLassoTool()
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawingData: Data
        var toolPicker: PKToolPicker?
        var shouldSkipNextUpdate = false

        init(drawingData: Binding<Data>) {
            _drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            shouldSkipNextUpdate = true
            drawingData = canvasView.drawing.dataRepresentation()
        }
    }
}
