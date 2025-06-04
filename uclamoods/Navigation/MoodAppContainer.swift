import SwiftUI

struct MoodAppContainer: View {
    @StateObject private var router = MoodAppRouter()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Consistent background
                Color.black.edgesIgnoringSafeArea(.all)
                
                Group {
                    switch router.currentSection {
                    case .auth:
                        AuthFlowView()
                        
                    case .main:
                        MainAppView()
                        
                    case .moodFlow:
                        MoodFlowContainer()
                    }
                }
            }
            .environmentObject(router)
            .onAppear {
                router.setScreenSize(geometry.size)
                // Check authentication status on app launch
                AuthenticationService.shared.checkAuthenticationStatus()
            }
            .onChange(of: geometry.size) { _, newSize in
                router.setScreenSize(newSize)
            }
            .onReceive(AuthenticationService.shared.$isAuthenticated) { isAuthenticated in
                // Handle authentication state changes
                if isAuthenticated && router.currentSection == .auth {
                    // User just logged in, navigate to main app
                    router.navigateToMainApp()
                } else if !isAuthenticated && router.currentSection != .auth {
                    // User logged out or token expired, go to auth
                    router.currentSection = .auth
                    router.currentAuthScreen = .signIn
                }
            }
        }
    }
}

// MARK: - Network Request Interceptor for Token Refresh
class AuthenticatedURLSession {
    static let shared = AuthenticatedURLSession()
    
    private init() {}
    
    func dataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        var authenticatedRequest = request
        
        // Add auth token
        if let token = AuthenticationService.shared.getAccessToken() {
            authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: authenticatedRequest)
        
        // Check if we got a 401 (unauthorized)
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            // Try to refresh the token
            await AuthenticationService.shared.refreshAccessToken()
            
            // Retry the request with new token
            if let newToken = AuthenticationService.shared.getAccessToken() {
                authenticatedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                return try await URLSession.shared.data(for: authenticatedRequest)
            } else {
                // Refresh failed, throw error
                throw AuthenticationError.invalidCredentials
            }
        }
        
        return (data, response)
    }
}

extension AnyTransition {
    static var scaleAndCrossFade: AnyTransition {
        // Symmetrical: new view scales up from 0.97 & fades in, old view scales down to 0.97 & fades out.
        // The `anchor: .center` ensures scaling is from the center.
        let transition = AnyTransition.opacity.combined(with: .scale(scale: 0.97, anchor: .center))
        // Adjust duration for smoothness. 0.3s to 0.4s is usually good.
        return transition.animation(.easeInOut(duration: 0.35))
    }
}

// MARK: - Auth Flow (Same as before)
struct AuthFlowView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        Group {
            switch router.currentAuthScreen {
            case .signIn:
                SignInView()
                
            case .signUp:
                SignUpView()
            }
        }
        .transition(.scaleAndCrossFade)
        .id(router.currentAuthScreen)
    }
}

// MARK: - 5-Tab Main App with Swipe Navigation (MODIFIED)
struct MainAppView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            TabView(selection: $router.selectedMainTab) {
                // Home Tab
                HomeFeedView()
                    .tag(MoodAppRouter.MainTab.home)
                
                // Map Tab
                MapView()
                    .tag(MoodAppRouter.MainTab.map)
                    .environmentObject(locationManager)
                
                // Analytics Tab
                SocialAnalyticsView()
                    .tag(MoodAppRouter.MainTab.analytics)
                
                // Profile Tab
                NavigationView {
                    ProfileView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tag(MoodAppRouter.MainTab.profile)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default dots
            .ignoresSafeArea(.all)
            
            // Custom tab bar overlay
            VStack {
                Spacer()
                FiveTabBar()
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            if router.selectedMainTab == nil {
                router.selectTab(.home)
            }
        }
    }
}

// MARK: - Custom 3-Tab Bar with Prominent Check-In Button
struct FiveTabBar: View { // RENAMED from ThreeTabBar
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        HStack {
            // Home Tab
            TabBarButton(
                tab: .home,
                isSelected: router.selectedMainTab == .home
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    router.selectTab(.home)
                }
            }
            
            Spacer() // Spacer 1
            
            // Map Tab (NEW)
            TabBarButton(
                tab: .map,
                isSelected: router.selectedMainTab == .map
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    router.selectTab(.map)
                }
            }
            
            Spacer() // Spacer 2
            
            // Check-In Button (Prominent Middle Button)
            CheckInButton {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                
                router.navigateToMoodFlow()
            }
            
            Spacer() // Spacer 3
            
            // Analytics Tab (NEW)
            TabBarButton(
                tab: .analytics,
                isSelected: router.selectedMainTab == .analytics
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    router.selectTab(.analytics)
                }
            }
            
            Spacer() // Spacer 4
            
            // Profile Tab
            TabBarButton(
                tab: .profile,
                isSelected: router.selectedMainTab == .profile
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    router.selectTab(.profile)
                }
            }
        }
        .padding(.horizontal, 20) // Adjusted horizontal padding slightly for more items
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.black.opacity(0.1)))
        )
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 25, bottomLeading: 0,
            bottomTrailing: 0, topTrailing: 25
        )))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        .ignoresSafeArea(edges: .bottom)
    }
}


// MARK: - Tab Bar Button Component
struct TabBarButton: View {
    let tab: MoodAppRouter.MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.iconNameFilled : tab.iconName)
                    .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Prominent Check-In Button
struct CheckInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .pink.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Pulsing animation ring
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .opacity(isPressed ? 0 : 1)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Continuous subtle pulse animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPressed = true
            }
        }
    }
}

// MARK: - Mood Flow Container (Same as before)
struct MoodFlowContainer: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch router.currentMoodFlowScreen {
                case .energySelection:
                    EnergySelectionView()
                        .moodTransition(
                            style: router.moodFlowTransitionStyle,
                            progress: router.moodFlowTransitionProgress,
                            origin: router.moodFlowTransitionOrigin,
                            size: geometry.size
                        )
                    
                case .emotionSelection(let energyLevel):
                    EmotionSelectionView(energyLevel: energyLevel)
                        .moodTransition(
                            style: router.moodFlowTransitionStyle,
                            progress: router.moodFlowTransitionProgress,
                            origin: router.moodFlowTransitionOrigin,
                            size: geometry.size
                        )
                    
                case .completeCheckIn(let emotion):
                    CompleteCheckInView(emotion: emotion)
                        .moodTransition(
                            style: router.moodFlowTransitionStyle,
                            progress: router.moodFlowTransitionProgress,
                            origin: router.moodFlowTransitionOrigin,
                            size: geometry.size
                        )
                }
            }
        }
    }
}

#Preview {
    MoodAppContainer()
}
