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
    case custom((Bool) -> AnyTransition) // For truly custom transitions
}

// MARK: - Screen Definitions
enum AppSection {
    case auth          // Sign in/up flows
    case main          // Home, settings, friends, stats
    case moodFlow      // Energy/emotion/checkin with custom transitions
}

enum AuthScreen: String, CaseIterable {
    case signIn = "signIn"
    case signUp = "signUp"
    case completeProfile = "completeProfile"
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

// MARK: - Updated Router for 3-Tab Navigation
class MoodAppRouter: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSection: AppSection = .auth
    @Published var currentAuthScreen: AuthScreen = .signIn
    @Published var selectedMainTab: MainTab = .home // NEW: 3-tab structure
    @Published var currentMoodFlowScreen: MoodFlowScreen = .energySelection
    
    // MARK: - Custom Transition Properties (for mood flow only)
    @Published var isAnimatingMoodFlow = false
    @Published var moodFlowTransitionProgress: CGFloat = 0
    @Published var moodFlowTransitionOrigin: CGPoint = .zero
    @Published var moodFlowTransitionStyle: TransitionStyle = .bubbleExpand
    
    // MARK: - Screen size for calculations
    private var screenSize: CGSize = .zero
    
    // MARK: - Animation durations
    let fadeOutDuration: Double = 0.4
    let fadeInDuration: Double = 0.5
    
    // MARK: - 3-Tab Structure
    enum MainTab: String, CaseIterable, Identifiable {
        case home = "home"
        case checkIn = "checkIn"
        case profile = "profile"
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .home: return "Feed"
            case .checkIn: return "Check In"
            case .profile: return "Profile"
            }
        }
        
        var iconName: String {
            switch self {
            case .home: return "house"
            case .checkIn: return "plus.circle"
            case .profile: return "person.circle"
            }
        }
        
        var iconNameFilled: String {
            switch self {
            case .home: return "house.fill"
            case .checkIn: return "plus.circle.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }
    
    // MARK: - Setup
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
    
    // MARK: - Auth Navigation (simple state changes)
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
    
    func navigateToCompleteProfile() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentAuthScreen = .completeProfile
        }
    }
    
    // MARK: - Section Navigation
    func navigateToMainApp() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSection = .main
            selectedMainTab = .home // Reset to home when entering main app
        }
    }
    
    func navigateToMoodFlow() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSection = .moodFlow
            // Reset mood flow to beginning
            currentMoodFlowScreen = .energySelection
            moodFlowTransitionProgress = 0
        }
    }
    
    func signOut() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSection = .auth
            currentAuthScreen = .signIn
            selectedMainTab = .home
        }
    }
    
    // MARK: - Main App Tab Navigation (swipe-based)
    func selectTab(_ tab: MainTab) {
        // Special handling for check-in button
        if tab == .checkIn {
            // Don't switch to check-in tab, instead navigate to mood flow
            navigateToMoodFlow()
        } else {
            // Normal tab selection for home and profile
            selectedMainTab = tab
        }
    }
    
    // Programmatic navigation to specific tabs
    func navigateToHome() {
        selectedMainTab = .home
    }
    
    func navigateToProfile() {
        selectedMainTab = .profile
    }
    
    // MARK: - Mood Flow Navigation (custom transitions)
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
            // Exit mood flow and return to main app
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSection = .main
            }
        }
    }
    
    // MARK: - Private Helpers
    private func getTransitionOriginForEnergyLevel(_ energyLevel: EmotionDataProvider.EnergyLevel) -> CGPoint {
        guard screenSize.width > 0 && screenSize.height > 0 else {
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
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
        
        // 1. Fade out current screen
        withAnimation(.easeInOut(duration: fadeOutDuration)) {
            moodFlowTransitionProgress = 1
        }
        
        // 2. Change screen and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration + 0.05) {
            self.currentMoodFlowScreen = screen
            self.moodFlowTransitionStyle = currentTransitionStyle
            
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: self.fadeInDuration)) {
                    self.moodFlowTransitionProgress = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeInDuration + 0.1) {
                    self.isAnimatingMoodFlow = false
                }
            }
        }
    }
}
