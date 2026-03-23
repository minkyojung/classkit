import SwiftUI
import SwiftData
import PhotosUI

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var bio = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?

    var onComplete: () -> Void

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        photoPicker
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("기본 정보") {
                    TextField("이름", text: $name)
                    TextField("자기소개 (선택)", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("프로필 설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { createTeacher() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Photo Picker

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            if let data = profileImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profileImageData = data
                }
            }
        }
    }

    // MARK: - Create

    private func createTeacher() {
        let teacher = Teacher(
            appleUserID: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            bio: bio.trimmingCharacters(in: .whitespaces)
        )
        teacher.profileImageData = profileImageData
        modelContext.insert(teacher)
        onComplete()
    }
}
