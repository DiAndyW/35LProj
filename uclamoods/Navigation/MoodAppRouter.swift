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

class MoodAppRouter: ObservableObject {
//    @Published private(set) var currentScreen: MoodAppScreen = .energySelection
    @Published private(set) var currentScreen: MoodAppScreen = .signIn
    @Published private(set) var isAnimating = false
    @Published private(set) var transitionProgress: CGFloat = 0 // 0 to 1
    
    // Origin point for transitions that need it (like bubbleExpand)
    @Published var transitionOrigin: CGPoint = .zero
    @Published private(set) var transitionStyle: TransitionStyle = .bubbleExpand
    
    // Screen size for calculating positions
    private var screenSize: CGSize = .zero
    
    // Previous screen tracking for seamless back navigation
    private var previousScreen: MoodAppScreen?
    private var previousEnergyLevel: EmotionDataProvider.EnergyLevel?
    
    // Customizable durations
    let fadeOutDuration: Double = 0.4
    let fadeInDuration: Double = 0.5
    
    // Set the screen size (call this from onAppear in your container view)
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
    
    func setTransitionStyle(_ style: TransitionStyle) {
        self.transitionStyle = style
    }
    
    func navigateToCompleteCheckIn(emotion: Emotion = EmotionDataProvider.defaultEmotion, from originPoint: CGPoint? = nil) {
        // Store current screen for back navigation
        storePreviousScreen()
        
        if let originPoint = originPoint {
            transitionOrigin = originPoint
        } else {
            // Default to the center if no origin provided
            transitionOrigin = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.75)
        }
        
        // Change transition style to moodMorph for this specific transition
        transitionStyle = .revealMask
        
        // Perform the transition
        performTransition(to: .completeCheckIn(emotion: emotion))
    }
    
    func navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel, from originPoint: CGPoint? = nil) {
        // Store current screen for back navigation
        storePreviousScreen()
        previousEnergyLevel = energyLevel
        
        // If a specific origin point is provided, use it
        if let originPoint = originPoint {
            transitionOrigin = originPoint
        } else {
            // Otherwise, calculate based on energy level
            transitionOrigin = getTransitionOriginForEnergyLevel(energyLevel)
        }
        
        transitionStyle = .bubbleExpand
        
        performTransition(to: .emotionSelection(energyLevel: energyLevel))
    }
    
    func navigateToEnergySelection(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        
        performTransition(to: .energySelection)
    }
    
    func navigateToHome(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        
        //Not needed for now, just for testing purposes
//        transitionStyle = .revealMask
        
        // Perform the transition
        performTransition(to: .home)
    }
    
    func navigateToStats(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        performTransition(to: .stats)
    }
    
    func navigateToFriends(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        performTransition(to: .friends)
    }
    
    func navigateToSettings(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        performTransition(to: .settings)
    }
    
    func navigateToSignIn(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        
        //maybe need to add logic to make user not logged in anymore?
        performTransition(to: .signIn)
    }
    
    func navigateToSignUp(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        
        //maybe need to add logic to make user not logged in anymore?
        performTransition(to: .signUp)
    }
    
    func navigateToCompleteProfile(from originPoint: CGPoint? = nil) {
        storePreviousScreen()
        performTransition(to: .completeProfile)
    }
    
    func navigateBack(from originPoint: CGPoint? = nil) {
        if let originPoint = originPoint {
            transitionOrigin = originPoint
        }
        
        // Use bubble expand for back navigation
        transitionStyle = .bubbleExpand
        
        // Navigate back using our previousScreen information
        switch currentScreen {
        case .emotionSelection:
            performTransition(to: .energySelection)
            
        case .completeCheckIn:
            // Go back to emotion selection with the stored energy level
            if let energyLevel = previousEnergyLevel {
                performTransition(to: .emotionSelection(energyLevel: energyLevel))
            } else {
                // Fallback
                performTransition(to: .emotionSelection(energyLevel: .medium))
            }
            
        case .energySelection:
            // Already at the root screen, do nothing or handle as needed
            break
            
        case .home:
            // Root screen
            break
            
        case .signIn:
            // Root screen
            break
            
        case .settings:
            // Root screen
            break
            
        case .friends:
            // Root screen
            break
            
        case .stats:
            // Root Screen
            break
            
        case .signUp:
            performTransition(to: .signIn)
            
        case .completeProfile:
            //Root screen
            break
        }
    
        
    }
    
    private func storePreviousScreen() {
        previousScreen = currentScreen
        
        // Store energy level when appropriate
        if case .emotionSelection(let energyLevel) = currentScreen {
            previousEnergyLevel = energyLevel
        }
    }
    
    private func getTransitionOriginForEnergyLevel(_ energyLevel: EmotionDataProvider.EnergyLevel) -> CGPoint {
        // Make sure we have valid screen dimensions
        guard screenSize.width > 0 && screenSize.height > 0 else {
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        }
        
        // Calculate origin point based on energy level
        switch energyLevel {
        case .high:
            // High energy: start from top of screen
            return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.35)
        case .medium:
            // Medium energy: start from middle of screen
            return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.6)
        case .low:
            // Low energy: start from bottom of screen
            return CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.8)
        }
    }
    
    // In MoodAppRouter.swift, modify the performTransition method:

    private func performTransition(to screen: MoodAppScreen) {
        guard !isAnimating else { return }
        
        isAnimating = true
        
        // Store the current transition style to maintain consistency
        let currentTransitionStyle = transitionStyle
        
        // 1. FADE OUT: Animate transition progress from 0 to 1
        withAnimation(.easeInOut(duration: fadeOutDuration)) {
            transitionProgress = 1
        }
        
        // 2. CHANGE SCREEN: After first animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration + 0.05) { // Small delay added
            // Change to the new screen
            self.currentScreen = screen
            
            // Make sure we're still using the same transition style
            self.transitionStyle = currentTransitionStyle
            
            // Important: Force layout update before starting the next animation
            // by updating in the next runloop
            DispatchQueue.main.async {
                // 3. FADE IN: Animate transition progress from 1 to 0 for the new screen
                withAnimation(.easeInOut(duration: self.fadeInDuration)) {
                    self.transitionProgress = 0
                }
                
                // 4. FINALIZE: Reset animation state when completely finished
                DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeInDuration + 0.1) {
                    self.isAnimating = false
                }
            }
        }
    }
}
