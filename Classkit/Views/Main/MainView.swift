import SwiftUI
import SwiftData

struct MainView: View {
    @Query(sort: \Classroom.createdAt, order: .reverse)
    private var classrooms: [Classroom]

    @Environment(\.modelContext) private var modelContext
    @State private var selectedClassroom: Classroom?
    @State private var showCreateSheet = false

    var body: some View {
        NavigationSplitView {
            ClassroomListView(
                classrooms: classrooms,
                selectedClassroom: $selectedClassroom,
                onAdd: { showCreateSheet = true },
                onDelete: deleteClassroom
            )
        } detail: {
            if let classroom = selectedClassroom {
                ClassroomDetailView(classroom: classroom)
            } else {
                ContentUnavailableView(
                    "교실을 선택하세요",
                    systemImage: "rectangle.inset.filled.and.person.filled",
                    description: Text("왼쪽에서 교실을 선택하거나 새 교실을 만드세요")
                )
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateClassroomSheet()
        }
    }

    private func deleteClassroom(_ classroom: Classroom) {
        if selectedClassroom?.id == classroom.id {
            selectedClassroom = nil
        }
        modelContext.delete(classroom)
    }
}

#Preview {
    MainView()
        .modelContainer(for: Classroom.self, inMemory: true)
}
