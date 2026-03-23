import SwiftUI
import SwiftData

struct ScanResultView: View {
    let imageData: Data
    let classroom: Classroom

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var recognizedText = ""
    @State private var title = ""
    @State private var isProcessing = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imagePreview
                    resultSection
                }
                .padding()
            }
            .navigationTitle("스캔 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(isProcessing || recognizedText.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .task {
                await performOCR()
            }
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        Group {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
            }
        }
    }

    // MARK: - Result Section

    @ViewBuilder
    private var resultSection: some View {
        if isProcessing {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("텍스트 인식 중...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else if let error = errorMessage {
            ContentUnavailableView(
                "인식 실패",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                TextField("제목 (선택)", text: $title)
                    .font(.headline)
                    .textFieldStyle(.roundedBorder)

                GroupBox {
                    TextEditor(text: $recognizedText)
                        .font(.body)
                        .frame(minHeight: 200)
                } label: {
                    Label("인식된 텍스트", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
    }

    // MARK: - OCR

    private func performOCR() async {
        guard let uiImage = UIImage(data: imageData) else {
            errorMessage = "이미지를 불러올 수 없습니다"
            isProcessing = false
            return
        }

        do {
            let text = try await OCRService.recognizeText(from: uiImage)
            recognizedText = text
            if text.isEmpty {
                errorMessage = "텍스트를 인식하지 못했습니다. 다른 이미지를 시도해보세요."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    // MARK: - Save

    private func save() {
        let problemTitle = title.trimmingCharacters(in: .whitespaces)
        let problem = ScannedProblem(
            imageData: imageData,
            recognizedText: recognizedText,
            title: problemTitle.isEmpty ? "스캔 \(Date().formatted(.dateTime.month().day().hour().minute()))" : problemTitle
        )
        problem.classroom = classroom
        modelContext.insert(problem)
        dismiss()
    }
}
