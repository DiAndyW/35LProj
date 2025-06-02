import SwiftUI

@main
struct uclamoodsApp: App {
    @StateObject private var userDataProvider = UserDataProvider.shared
    init() {
        // Initialize authentication service early
        configureAuthentication()
    }
    
    var body: some Scene {
        WindowGroup {
            MoodAppContainer()
                .environmentObject(userDataProvider)
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAuthentication() {
        // This ensures auth service is initialized and loads stored tokens
        _ = AuthenticationService.shared
    }
}
