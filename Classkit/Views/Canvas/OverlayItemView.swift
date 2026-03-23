import SwiftUI
import SwiftData

struct OverlayItemView: View {
    @Bindable var overlay: CanvasOverlay
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isEditing = false

    var body: some View {
        Group {
            switch overlay.type {
            case .text:
                textContent
            case .image:
                imageContent
            case .shape:
                shapeContent
            }
        }
        .frame(width: overlay.width, height: overlay.height)
        .rotationEffect(.degrees(overlay.rotation))
        .position(
            x: overlay.x + dragOffset.width,
            y: overlay.y + dragOffset.height
        )
        .gesture(dragGesture)
        .onTapGesture { onSelect() }
        .overlay {
            if isSelected {
                selectionBorder
            }
        }
    }

    // MARK: - Text

    private var textContent: some View {
        Group {
            if isEditing {
                TextField("텍스트 입력", text: Binding(
                    get: { overlay.text ?? "" },
                    set: { overlay.text = $0 }
                ), axis: .vertical)
                .font(.system(size: overlay.fontSize ?? 16))
                .padding(8)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onSubmit { isEditing = false }
            } else {
                Text(overlay.text?.isEmpty == false ? overlay.text! : "텍스트 입력")
                    .font(.system(size: overlay.fontSize ?? 16))
                    .foregroundStyle(overlay.text?.isEmpty == false ? .primary : .secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.white.opacity(0.01))
                    .onTapGesture(count: 2) { isEditing = true }
                    .onTapGesture { onSelect() }
            }
        }
    }

    // MARK: - Image

    private var imageContent: some View {
        Group {
            if let data = overlay.imageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    // MARK: - Shape

    private var shapeContent: some View {
        let strokeColor = Color(hex: overlay.strokeColorHex ?? "#000000") ?? .black
        let lineWidth = overlay.strokeWidth ?? 2

        return Group {
            switch overlay.shapeType {
            case .rectangle:
                Rectangle()
                    .stroke(strokeColor, lineWidth: lineWidth)
            case .circle:
                Ellipse()
                    .stroke(strokeColor, lineWidth: lineWidth)
            case .line:
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: overlay.width, y: overlay.height))
                }
                .stroke(strokeColor, lineWidth: lineWidth)
            case .arrow:
                Path { path in
                    path.move(to: CGPoint(x: 0, y: overlay.height / 2))
                    path.addLine(to: CGPoint(x: overlay.width, y: overlay.height / 2))
                    // arrowhead
                    path.move(to: CGPoint(x: overlay.width - 12, y: overlay.height / 2 - 8))
                    path.addLine(to: CGPoint(x: overlay.width, y: overlay.height / 2))
                    path.addLine(to: CGPoint(x: overlay.width - 12, y: overlay.height / 2 + 8))
                }
                .stroke(strokeColor, lineWidth: lineWidth)
            case nil:
                EmptyView()
            }
        }
    }

    // MARK: - Selection Border

    private var selectionBorder: some View {
        Rectangle()
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            .frame(width: overlay.width + 8, height: overlay.height + 8)
            .position(
                x: overlay.x + dragOffset.width,
                y: overlay.y + dragOffset.height
            )
            .overlay(alignment: .topTrailing) {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .red)
                }
                .position(
                    x: overlay.x + dragOffset.width + overlay.width / 2 + 4,
                    y: overlay.y + dragOffset.height - overlay.height / 2 - 4
                )
            }
            .overlay(alignment: .bottomTrailing) {
                // Resize handle
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption2)
                    .padding(4)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .position(
                        x: overlay.x + dragOffset.width + overlay.width / 2,
                        y: overlay.y + dragOffset.height + overlay.height / 2
                    )
                    .gesture(resizeGesture)
            }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                overlay.x += value.translation.width
                overlay.y += value.translation.height
                dragOffset = .zero
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                overlay.width = max(50, overlay.width + value.translation.width)
                overlay.height = max(30, overlay.height + value.translation.height)
            }
    }
}
