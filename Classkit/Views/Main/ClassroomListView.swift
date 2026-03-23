import SwiftUI

struct ClassroomListView: View {
    let classrooms: [ClassroomDTO]
    @Binding var selectedClassroomId: UUID?
    var onAdd: () -> Void
    var onDelete: (ClassroomDTO) -> Void

    @State private var searchText = ""

    private var filteredClassrooms: [ClassroomDTO] {
        if searchText.isEmpty {
            return classrooms
        }
        return classrooms.filter {
            $0.studentName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredClassrooms, selection: $selectedClassroomId) { classroom in
            ClassroomRow(classroom: classroom)
                .tag(classroom.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onDelete(classroom)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
        }
        .navigationTitle("교실")
        .searchable(text: $searchText, prompt: "학생 이름 검색")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("교실 추가")
            }
        }
        .overlay {
            if classrooms.isEmpty {
                ContentUnavailableView(
                    "아직 교실이 없습니다",
                    systemImage: "plus.circle",
                    description: Text("+ 버튼을 눌러 첫 교실을 만들어보세요")
                )
            }
        }
    }
}
