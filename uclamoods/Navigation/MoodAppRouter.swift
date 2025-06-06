import SwiftUI
import Combine

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

class MoodAppRouter: ObservableObject {
    @Published var currentSection: AppSection = .auth
    @Published var currentAuthScreen: AuthScreen = .signIn
    @Published var selectedMainTab: MainTab = .home
    @Published var currentMoodFlowScreen: MoodFlowScreen = .energySelection
    @Published var isAnimatingMoodFlow = false
    @Published var moodFlowTransitionProgress: CGFloat = 0
    @Published var moodFlowTransitionOrigin: CGPoint = .zero
    @Published var moodFlowTransitionStyle: TransitionStyle = .bubbleExpand
    
    @Published var initialEmotionIDForSelection: Emotion.ID?
    
    let homeFeedNeedsRefresh = PassthroughSubject<Void, Never>()
    let commentCountUpdated = PassthroughSubject<(postId: String, newCount: Int), Never>()
    let userDidBlock = PassthroughSubject<String, Never>()
    let homeTabTappedAgain = PassthroughSubject<Void, Never>()
    let profileTabTappedAgain = PassthroughSubject<Void, Never>()
    let mapTabTappedAgain = PassthroughSubject<Void, Never>()
    let analyticsTabTappedAgain = PassthroughSubject<Void, Never>()
    
    @Published var tabWithActiveDetailView: MainTab? = nil {
        didSet {
            print("[MoodAppRouter] tabWithActiveDetailView changed to: \(String(describing: tabWithActiveDetailView))")
        }
    }
    
    @Published var selectedSortMethod: FeedSortMethod = .relevance
    
    private var screenSize: CGSize = .zero
    let fadeOutDuration: Double = 0.4
    let fadeInDuration: Double = 0.5
    
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
    
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
    
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
        AuthenticationService.shared.logout()
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentSection = .auth
            self.currentAuthScreen = .signIn
            self.selectedMainTab = .home
            self.tabWithActiveDetailView = nil
        }
    }
    
    func selectTab(_ tab: MainTab) {
        if tab == .checkIn {
            navigateToMoodFlow()
        } else {
            if selectedMainTab != tab {
                selectedMainTab = tab
            } else {
                // Same tab was tapped again, broadcast an event
                switch tab {
                    case .home:
                        print("[MoodAppRouter] Home tab tapped again.")
                        homeTabTappedAgain.send()
                    case .profile:
                        print("[MoodAppRouter] Profile tab tapped again.")
                        profileTabTappedAgain.send()
                    case .map:
                        print("[MoodAppRouter] Map tab tapped again.")
                        mapTabTappedAgain.send()
                    case .analytics:
                        print("[MoodAppRouter] Analytics tab tapped again.")
                        analyticsTabTappedAgain.send()
                    default:
                        break // No action for other tabs
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
    
    func navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel, initialEmotionID: Emotion.ID? = nil, from originPoint: CGPoint? = nil) {
        if let originPoint = originPoint {
            moodFlowTransitionOrigin = originPoint
        } else {
            moodFlowTransitionOrigin = getTransitionOriginForEnergyLevel(energyLevel)
        }
        moodFlowTransitionStyle = .bubbleExpand
        self.initialEmotionIDForSelection = initialEmotionID
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
    
    private func getTransitionOriginForEnergyLevel(_ energyLevel: EmotionDataProvider.EnergyLevel) -> CGPoint {
        guard screenSize.width > 0 && screenSize.height > 0 else {
            let bounds = UIScreen.main.bounds
            return CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        }
        
        switch energyLevel {
            case .high:
                return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.3)
            case .medium:
                return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.55)
            case .low:
                return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.8)
        }
    }
    
    private func performMoodFlowTransition(to screen: MoodFlowScreen) {
        guard !isAnimatingMoodFlow else { return }
        
        isAnimatingMoodFlow = true
        let currentTransitionStyle = moodFlowTransitionStyle
        
        withAnimation(.easeInOut(duration: fadeOutDuration)) {
            moodFlowTransitionProgress = 1
        }
        
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
