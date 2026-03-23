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
    var showToolPicker: Bool = true
    var onCoordinatorReady: ((Coordinator) -> Void)?

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

        // Show system tool picker with async first responder for reliability
        if !isReadOnly && showToolPicker {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvas)
            toolPicker.addObserver(canvas)
            context.coordinator.toolPicker = toolPicker
            context.coordinator.canvasView = canvas

            // Delay becomeFirstResponder to ensure view hierarchy is ready
            DispatchQueue.main.async {
                canvas.becomeFirstResponder()
                self.onCoordinatorReady?(context.coordinator)
            }
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
        weak var canvasView: PKCanvasView?
        var shouldSkipNextUpdate = false

        init(drawingData: Binding<Data>) {
            _drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            shouldSkipNextUpdate = true
            drawingData = canvasView.drawing.dataRepresentation()
        }

        func undo() {
            canvasView?.undoManager?.undo()
        }

        func redo() {
            canvasView?.undoManager?.redo()
        }

        var canUndo: Bool {
            canvasView?.undoManager?.canUndo ?? false
        }

        var canRedo: Bool {
            canvasView?.undoManager?.canRedo ?? false
        }
    }
}
