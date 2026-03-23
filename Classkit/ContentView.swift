import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var authManager = AuthManager()

    var body: some View {
        Group {
            if authManager.isLoading && !authManager.isSignedIn {
                ProgressView("로딩 중...")
            } else if authManager.isSignedIn {
                if authManager.isTeacher {
                    MainView()
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                signOutButton
                            }
                        }
                } else if authManager.isStudent {
                    StudentMainView(onSwitchRole: {
                        Task { await authManager.signOut() }
                    })
                } else {
                    // Profile not loaded yet or role not set
                    ProgressView("프로필 로딩 중...")
                        .task { await authManager.fetchProfile() }
                }
            } else {
                LoginView()
            }
        }
        .environment(authManager)
    }

    private var signOutButton: some View {
        Button {
            Task { await authManager.signOut() }
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
        }
        .accessibilityLabel("로그아웃")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Teacher.self, inMemory: true)
}
