import SwiftUI

enum MoodAppScreen: Equatable {
    case energySelection
    case emotionSelection(energyLevel: EmotionDataProvider.EnergyLevel)
    case completeCheckIn(emotion: Emotion)
    case home
    case signIn
    case settings
    case friends
    case stats
    case signUp
    case completeProfile
}

enum TransitionStyle {
    case fadeScale
    case zoomSlide
    case bubbleExpand
    case revealMask
    case moodMorph
    case blobToTop(emotion: Emotion)
    case custom((Bool) -> AnyTransition)
}

enum AppSection {
    case auth
    case main
    case moodFlow
}

enum AuthScreen: String, CaseIterable {
    case signIn = "signIn"
    case signUp = "signUp"
}

enum MainScreen: String, CaseIterable, Hashable {
    case home = "home"
    case settings = "settings"
    case friends = "friends"
    case stats = "stats"
}

enum MoodFlowScreen: Equatable {
    case energySelection
    case emotionSelection(energyLevel: EmotionDataProvider.EnergyLevel)
    case completeCheckIn(emotion: Emotion)
}

// MARK: - Updated Router for 5-Item Navigation
class MoodAppRouter: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSection: AppSection = .auth
    @Published var currentAuthScreen: AuthScreen = .signIn
    @Published var selectedMainTab: MainTab = .home
    @Published var currentMoodFlowScreen: MoodFlowScreen = .energySelection
     
    // MARK: - Custom Transition Properties (for mood flow only)
    @Published var isAnimatingMoodFlow = false
    @Published var moodFlowTransitionProgress: CGFloat = 0
    @Published var moodFlowTransitionOrigin: CGPoint = .zero
    @Published var moodFlowTransitionStyle: TransitionStyle = .bubbleExpand
    
    @Published var isDetailViewShowing: Bool = false
     
    // MARK: - Screen size for calculations
    private var screenSize: CGSize = .zero
     
    // MARK: - Animation durations
    let fadeOutDuration: Double = 0.4
    let fadeInDuration: Double = 0.5
     
    // MARK: - 5-Item Tab Structure (MODIFIED)
    enum MainTab: String, CaseIterable, Identifiable {
        case home = "home"
        case map = "map"
        case checkIn = "checkIn"
        case analytics = "analytics"
        case profile = "profile"
         
        var id: String { self.rawValue }
         
        var title: String {
            switch self {
            case .home: return "Feed"
            case .map: return "Map"
            case .checkIn: return "Check In"
            case .analytics: return "Analytics"
            case .profile: return "Profile"
            }
        }
         
        var iconName: String {
            switch self {
            case .home: return "house"
            case .map: return "map"
            case .checkIn: return "plus.circle"
            case .analytics: return "chart.bar"
            case .profile: return "person.circle"
            }
        }
         
        var iconNameFilled: String {
            switch self {
            case .home: return "house.fill"
            case .map: return "map.fill"
            case .checkIn: return "plus.circle.fill"
            case .analytics: return "chart.bar.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }
     
    // MARK: - Setup
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
     
    // MARK: - Auth Navigation
    func navigateToSignIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentAuthScreen = .signIn
        }
    }
     
    func navigateToSignUp() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentAuthScreen = .signUp
        }
    }
     
    // MARK: - Section Navigation
    func navigateToMainApp() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSection = .main
            selectedMainTab = .home
        }
    }
     
    func navigateToMoodFlow() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSection = .moodFlow
            currentMoodFlowScreen = .energySelection
            moodFlowTransitionProgress = 0
        }
    }
     
    func signOut() {
        print("[MoodAppRouter] signOut: Initiating logout process.")
        AuthenticationService.shared.logout()
         
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentSection = .auth
            self.currentAuthScreen = .signIn
            self.selectedMainTab = .home
            print("[MoodAppRouter] signOut: UI state updated to show SignIn screen.")
        }
    }
     
    // MARK: - Main App Tab Navigation
    func selectTab(_ tab: MainTab) {
        if tab == .checkIn {
            navigateToMoodFlow()
        } else {
            if selectedMainTab != tab {
                 withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMainTab = tab
                }
            }
        }
    }
     
    func navigateToHome() {
        if currentSection != .main { currentSection = .main }
        selectTab(.home)
    }
     
    func navigateToProfile() {
        if currentSection != .main { currentSection = .main }
        selectTab(.profile)
    }

    func navigateToMap() {
        if currentSection != .main { currentSection = .main }
        selectTab(.map)
    }

    func navigationToAnalytics() {
        if currentSection != .main { currentSection = .main }
        selectTab(.analytics)
    }
     
    // MARK: - Mood Flow Navigation
    func setMoodFlowTransitionStyle(_ style: TransitionStyle) {
        moodFlowTransitionStyle = style
    }
     
    func navigateToEnergySelection(from originPoint: CGPoint? = nil) {
        if let originPoint = originPoint {
            moodFlowTransitionOrigin = originPoint
        }
        moodFlowTransitionStyle = .bubbleExpand
        performMoodFlowTransition(to: .energySelection)
    }
     
    func navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel, from originPoint: CGPoint? = nil) {
        if let originPoint = originPoint {
            moodFlowTransitionOrigin = originPoint
        } else {
            moodFlowTransitionOrigin = getTransitionOriginForEnergyLevel(energyLevel)
        }
        moodFlowTransitionStyle = .bubbleExpand
        performMoodFlowTransition(to: .emotionSelection(energyLevel: energyLevel))
    }
     
    func navigateToCompleteCheckIn(emotion: Emotion, from originPoint: CGPoint? = nil) {
        if let originPoint = originPoint {
            moodFlowTransitionOrigin = originPoint
        } else {
            moodFlowTransitionOrigin = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.75)
        }
        moodFlowTransitionStyle = .bubbleExpand
        performMoodFlowTransition(to: .completeCheckIn(emotion: emotion))
    }
     
    func navigateBackInMoodFlow(from originPoint: CGPoint? = nil) {
        if let originPoint = originPoint {
            moodFlowTransitionOrigin = originPoint
        }
        moodFlowTransitionStyle = .bubbleExpand
         
        switch currentMoodFlowScreen {
        case .emotionSelection:
            performMoodFlowTransition(to: .energySelection)
        case .completeCheckIn:
            performMoodFlowTransition(to: .energySelection)
        case .energySelection:
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSection = .main
            }
        }
    }
     
    // MARK: - Private Helpers
    private func getTransitionOriginForEnergyLevel(_ energyLevel: EmotionDataProvider.EnergyLevel) -> CGPoint {
        guard screenSize.width > 0 && screenSize.height > 0 else {
            let bounds = UIScreen.main.bounds
            return CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        }
         
        switch energyLevel {
        case .high:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.35)
        case .medium:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.6)
        case .low:
            return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.8)
        }
    }
     
    private func performMoodFlowTransition(to screen: MoodFlowScreen) {
        guard !isAnimatingMoodFlow else { return }
         
        isAnimatingMoodFlow = true
        let currentTransitionStyle = moodFlowTransitionStyle
         
        withAnimation(.easeInOut(duration: fadeOutDuration)) {
            moodFlowTransitionProgress = 1 // Animate out
        }
         
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration + 0.05) {
            self.currentMoodFlowScreen = screen
            self.moodFlowTransitionStyle = currentTransitionStyle
             
            // Ensure this runs on the main thread for UI updates
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: self.fadeInDuration)) {
                    self.moodFlowTransitionProgress = 0 // Animate in
                }
                 
                // Finalize animation state
                DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeInDuration + 0.1) {
                    self.isAnimatingMoodFlow = false
                }
            }
        }
    }
}
