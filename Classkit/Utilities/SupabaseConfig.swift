import Foundation
import Auth
import PostgREST

enum SupabaseConfig {
    static let url = URL(string: "https://ncocqwswnovcoayvkehi.supabase.co")!
    static let anonKey = "sb_publishable_a-Pf7YtDF-pcGAJNQl6uUg_y5DSEybU"

    static let headers: [String: String] = [
        "apikey": anonKey,
        "Authorization": "Bearer \(anonKey)"
    ]

    static let auth = AuthClient(
        url: url.appendingPathComponent("auth/v1"),
        headers: headers,
        flowType: .pkce,
        localStorage: KeychainLocalStorage()
    )

    static let database = PostgrestClient(
        configuration: .init(
            url: url.appendingPathComponent("rest/v1"),
            schema: "public",
            headers: headers
        )
    )
}
