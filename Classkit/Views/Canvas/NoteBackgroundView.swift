import SwiftUI

struct NoteBackgroundView: View {
    let backgroundType: NoteBackgroundType
    let size: CGSize

    private let lineSpacing: CGFloat = 32
    private let lineColor = Color.gray.opacity(0.2)

    var body: some View {
        Canvas { context, canvasSize in
            switch backgroundType {
            case .blank:
                break
            case .lined:
                drawLines(context: context, size: canvasSize)
            case .grid:
                drawGrid(context: context, size: canvasSize)
            case .dotted:
                drawDots(context: context, size: canvasSize)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(.white)
    }

    private func drawLines(context: GraphicsContext, size: CGSize) {
        var y = lineSpacing
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            y += lineSpacing
        }
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        drawLines(context: context, size: size)

        var x = lineSpacing
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            x += lineSpacing
        }
    }

    private func drawDots(context: GraphicsContext, size: CGSize) {
        let dotRadius: CGFloat = 1.5
        var y = lineSpacing
        while y < size.height {
            var x = lineSpacing
            while x < size.width {
                let rect = CGRect(
                    x: x - dotRadius,
                    y: y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(lineColor))
                x += lineSpacing
            }
            y += lineSpacing
        }
    }
}
