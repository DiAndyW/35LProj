import SwiftUI

@main
struct uclamoodsApp: App {
    init() {
        // Initialize authentication service early
        configureAuthentication()
    }
    
    var body: some Scene {
        WindowGroup {
            MoodAppContainer()
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAuthentication() {
        // This ensures auth service is initialized and loads stored tokens
        _ = AuthenticationService.shared
    }
}
