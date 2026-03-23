import SwiftUI
import Auth

struct MainView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var apiService = APIService()
    @State private var classrooms: [ClassroomDTO] = []
    @State private var selectedClassroomId: UUID?
    @State private var showCreateSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var selectedClassroom: ClassroomDTO? {
        classrooms.first { $0.id == selectedClassroomId }
    }

    var body: some View {
        NavigationSplitView {
            ClassroomListView(
                classrooms: classrooms,
                selectedClassroomId: $selectedClassroomId,
                onAdd: { showCreateSheet = true },
                onDelete: deleteClassroom
            )
            .overlay {
                if isLoading && classrooms.isEmpty {
                    ProgressView()
                }
            }
        } detail: {
            if let classroom = selectedClassroom {
                ClassroomDetailView(classroomDTO: classroom, apiService: apiService)
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.quaternary)
                    VStack(spacing: 8) {
                        Text("학생을 선택해주세요")
                            .font(.title3.weight(.semibold))
                        Text("왼쪽 목록에서 학생을 선택하면\n수업 정보를 확인할 수 있어요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateClassroomSheet(apiService: apiService) {
                Task { await loadClassrooms() }
            }
        }
        .task { await loadClassrooms() }
    }

    private func loadClassrooms() async {
        guard let userId = authManager.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            classrooms = try await apiService.fetchClassrooms(teacherId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteClassroom(_ classroom: ClassroomDTO) {
        if selectedClassroomId == classroom.id {
            selectedClassroomId = nil
        }
        Task {
            do {
                try await apiService.deleteClassroom(id: classroom.id)
                classrooms.removeAll { $0.id == classroom.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
