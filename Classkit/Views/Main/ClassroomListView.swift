import SwiftUI

struct ClassroomListView: View {
    let classrooms: [Classroom]
    @Binding var selectedClassroom: Classroom?
    var onAdd: () -> Void
    var onDelete: (IndexSet) -> Void

    @State private var searchText = ""

    private var filteredClassrooms: [Classroom] {
        if searchText.isEmpty {
            return classrooms
        }
        return classrooms.filter {
            $0.studentName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredClassrooms, selection: $selectedClassroom) { classroom in
            ClassroomRow(classroom: classroom)
                .tag(classroom)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if let index = classrooms.firstIndex(of: classroom) {
                            onDelete(IndexSet(integer: index))
                        }
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
