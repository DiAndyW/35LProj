import Foundation
import SwiftUI

// MARK: - User Data Provider (Singleton for Easy Access)
class UserDataProvider: ObservableObject {
    static let shared = UserDataProvider()
    
    @Published var currentUser: User?
    
    private init() {
        // Subscribe to auth service user changes
        AuthenticationService.shared.$currentUser
            .assign(to: &$currentUser)
    }
    
    // Convenience properties
    var userId: String? {
        currentUser?.id ?? AuthenticationService.shared.currentUserId
    }
    
    var username: String? {
        currentUser?.username
    }
    
    var email: String? {
        currentUser?.email
    }
    
    // Refresh user data
    func refreshUserData() async {
        do {
            _ = try await AuthenticationService.shared.fetchUserProfile()
        } catch {
            print("Failed to refresh user data: \(error)")
        }
    }
}
