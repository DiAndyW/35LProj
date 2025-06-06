import SwiftUI
import FluidGradient

struct MoodAppContainer: View {
    @StateObject private var router = MoodAppRouter()
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - Shared Gradient Properties (Moved here)
    @State private var gradientColors: [Color] = []
    @State private var gradientHighlights: [Color] = [.black]
    @State private var gradientSpeed: Double = 0.1 // Adjust default speed as needed
    private let colorPool: [Color] = [Color(hex: "403BFF"), Color(hex: "2C60F2"), .black]
    
    // MARK: - Shared Gradient Setup Method (Moved here)
    private func setupGradientColors() {
        var tempColors: [Color] = []
        // Start with a more subtle highlight, or an empty array if preferred
        var tempHighlights: [Color] = [Color.black.opacity(0.4)]
        
        let numBlobs = 3
        for _ in 0..<numBlobs {
            if let randomColor = colorPool.randomElement() {
                tempColors.append(randomColor)
            }
        }
        
        // Ensure black is present for a darker base, can be adjusted
        if !tempColors.contains(.black) {
            tempColors.insert(.black, at: Int.random(in: 0..<(tempColors.count + 1)))
        }
        if tempColors.filter({ $0 == .black }).count < 2 && numBlobs > 1 {
            tempColors.append(.black)
        }
        
        let numHighlights = 2
        for _ in 0..<numHighlights {
            // Make highlights a bit subtle or use lighter distinct colors
            if let randomHighlight = colorPool.randomElement()?.opacity(0.6) {
                tempHighlights.append(randomHighlight)
            }
        }
        // Optionally add a very subtle light highlight if the theme allows
        // tempHighlights.append(Color.white.opacity(0.15))
        
        self.gradientColors = tempColors
        self.gradientHighlights = tempHighlights
    }
    
    // Computed property for the shared gradient (Moved here)
    private var sharedFluidGradient: some View {
        FluidGradient(blobs: gradientColors,
                      highlights: gradientHighlights,
                      speed: gradientSpeed)
        .backgroundStyle(.black) // Set the canvas for the gradient itself to black
        .edgesIgnoringSafeArea(.all)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Consistent background
                sharedFluidGradient
                
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
            .background(.black)
            .environmentObject(router)
            .environmentObject(locationManager)
            .onAppear {
                router.setScreenSize(geometry.size)
                // Check authentication status on app launch
                AuthenticationService.shared.checkAuthenticationStatus()
                setupGradientColors()
                clearAppBadge()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Clear badge when app returns from background
                clearAppBadge()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Clear badge when app enters foreground
                clearAppBadge()
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
    
    private func clearAppBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("[Notification Service] App badge cleared")
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

// MARK: - Auth Flow
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
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $router.selectedMainTab) {
                HomeFeedView()
                    .tag(MoodAppRouter.MainTab.home)
                MapView()
                    .tag(MoodAppRouter.MainTab.map)
                SocialAnalyticsView()
                    .tag(MoodAppRouter.MainTab.analytics)
                NavigationView {
                    ProfileView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tag(MoodAppRouter.MainTab.profile)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                if router.tabWithActiveDetailView == nil || router.tabWithActiveDetailView != router.selectedMainTab {
                    FiveTabBar()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct FiveTabBar: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Home and Map
            HStack(spacing: 0) {
                TabBarButton(
                    tab: .home,
                    isSelected: router.selectedMainTab == .home
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        router.selectTab(.home)
                    }
                }
                .frame(maxWidth: .infinity)
                
                TabBarButton(
                    tab: .map,
                    isSelected: router.selectedMainTab == .map
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        router.selectTab(.map)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            // Center - Check-In Button
            CheckInButton {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                router.navigateToMoodFlow()
            }
            .frame(width: 80)
            
            // Right side - Analytics and Profile
            HStack(spacing: 0) {
                TabBarButton(
                    tab: .analytics,
                    isSelected: router.selectedMainTab == .analytics
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        router.selectTab(.analytics)
                    }
                }
                .frame(maxWidth: .infinity)
                
                TabBarButton(
                    tab: .profile,
                    isSelected: router.selectedMainTab == .profile
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        router.selectTab(.profile)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
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
                
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CheckInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
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
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
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
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
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
}

#Preview {
    MoodAppContainer()
}
