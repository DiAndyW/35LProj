import Foundation
import SwiftUI
import Combine

class UserDataProvider: ObservableObject {
    static let shared = UserDataProvider()
    
    @Published var currentUser: User? {
        didSet { // Use didSet for simple debugging
            print("[UserDataProvider]: currentUser didSet. New username: \(currentUser?.username ?? "nil"), Email: \(currentUser?.email ?? "nil")")
        }
    }
    
    // To store the subscription from .assign(to:)
    private var cancellable: AnyCancellable?
    
    private init() {
        print("[UserDataProvider]: Initializing and subscribing to AuthenticationService.shared.$currentUser")
        // Subscribe to auth service user changes
        // This assigns the value from AuthenticationService.shared.$currentUser to self.currentUser
        // The didSet observer above will then print when it changes.
        cancellable = AuthenticationService.shared.$currentUser
            .assign(to: \.currentUser, on: self) // `on: self` ensures it's assigned to this instance's property
    }
    
    var userId: String? {
        // Also good to log here if accessed and nil unexpectedly
        let id = currentUser?.id ?? AuthenticationService.shared.currentUserId
        // print("[UserDataProvider DEBUG] userId accessed. Value: \(id ?? "nil")")
        return id
    }
    
    // ... (rest of the class)
    func refreshUserData() async {
        print("[UserDataProvider]: refreshUserData: Called.")
        do {
            _ = try await AuthenticationService.shared.fetchUserProfile()
            print("[UserDataProvider]: refreshUserData: fetchUserProfile completed. CurrentUser in UserDataProvider: \(self.currentUser?.username ?? "nil")")
        } catch {
            print("[UserDataProvider]: refreshUserData: Failed to refresh user data: \(error.localizedDescription)")
        }
    }
}
