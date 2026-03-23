import Foundation
import Auth
import PostgREST

@Observable
final class AuthManager {
    // MARK: - State

    var currentUser: Auth.User?
    var userProfile: UserProfile?
    var isLoading = false
    var errorMessage: String?

    var isSignedIn: Bool { currentUser != nil }
    var isTeacher: Bool { userProfile?.role == .teacher }
    var isStudent: Bool { userProfile?.role == .student }

    private let auth = SupabaseConfig.auth
    private let db = SupabaseConfig.database

    // MARK: - Init

    init() {
        Task { await restoreSession() }
    }

    // MARK: - Session

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await auth.session
            currentUser = session.user
            await fetchProfile()
        } catch {
            currentUser = nil
            userProfile = nil
        }
    }

    // MARK: - Email Auth

    func signUpWithEmail(email: String, password: String, name: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await auth.signUp(
                email: email,
                password: password
            )
            currentUser = response.user

            let profile = UserProfile(
                id: response.user.id,
                role: role,
                name: name
            )
            try await db.from("profiles")
                .insert(profile)
                .execute()

            userProfile = profile
        } catch {
            errorMessage = "회원가입 실패: \(error.localizedDescription)"
        }
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            await fetchProfile()
        } catch {
            errorMessage = "로그인 실패: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        do {
            try await auth.signOut()
            currentUser = nil
            userProfile = nil
        } catch {
            errorMessage = "로그아웃 실패: \(error.localizedDescription)"
        }
    }

    // MARK: - Profile

    func fetchProfile() async {
        guard let userId = currentUser?.id else { return }

        do {
            let profile: UserProfile = try await db.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            userProfile = profile
        } catch {
            userProfile = nil
        }
    }

    func updateProfile(name: String? = nil, bio: String? = nil) async {
        guard let userId = currentUser?.id else { return }

        do {
            var updates: [String: String] = [:]
            if let name { updates["name"] = name }
            if let bio { updates["bio"] = bio }

            try await db.from("profiles")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()

            await fetchProfile()
        } catch {
            errorMessage = "프로필 업데이트 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - Models

enum UserRole: String, Codable {
    case teacher
    case student
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var role: UserRole
    var name: String
    var bio: String?
    var profileImageUrl: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, role, name, bio
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
    }
}
