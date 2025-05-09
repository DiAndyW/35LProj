import SwiftUI

enum MoodAppScreen: Equatable {
    case energySelection
    case emotionSelection(energyLevel: EmotionDataProvider.EnergyLevel)
    // Add other screens as needed
}

enum TransitionStyle {
    case fadeScale
    case zoomSlide
    case bubbleExpand
    case revealMask
    case moodMorph
    case custom((Bool) -> AnyTransition) // For truly custom transitions
}

class MoodAppRouter: ObservableObject {
    @Published private(set) var currentScreen: MoodAppScreen = .energySelection
    @Published private(set) var isAnimating = false
    @Published private(set) var transitionProgress: CGFloat = 0 // 0 to 1
    
    // Origin point for transitions that need it (like bubbleExpand)
    @Published var transitionOrigin: CGPoint = .zero
    
    // Screen size for calculating positions
    private var screenSize: CGSize = .zero
    
    // Customizable durations
    let fadeOutDuration: Double = 0.4
    let fadeInDuration: Double = 0.5
    let transitionStyle: TransitionStyle = .bubbleExpand
    
    // Set the screen size (call this from onAppear in your container view)
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
    
    func navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel, from originPoint: CGPoint? = nil) {
        // If a specific origin point is provided, use it
        if let originPoint = originPoint {
            transitionOrigin = originPoint
        } else {
            // Otherwise, calculate based on energy level
            transitionOrigin = getTransitionOriginForEnergyLevel(energyLevel)
        }
        
        performTransition(to: .emotionSelection(energyLevel: energyLevel))
    }
    
    func navigateBack(from originPoint: CGPoint? = CGPoint(x: 20, y: 20)) {
        // You could also calculate this based on the current energy level if needed
        if let originPoint = originPoint {
            transitionOrigin = originPoint
        }
        performTransition(to: .energySelection)
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
    
    private func performTransition(to screen: MoodAppScreen) {
        guard !isAnimating else { return }
        
        isAnimating = true
        
        // Animate transition progress from 0 to 1
        withAnimation(.easeInOut(duration: fadeOutDuration)) {
            transitionProgress = 1
        }
        
        // Change screen after halfway through the transition
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
            self.currentScreen = screen
            
            // Animate transition progress from 1 to 0 for the new screen
            withAnimation(.easeInOut(duration: self.fadeInDuration)) {
                self.transitionProgress = 0
            }
            
            // Reset animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeInDuration) {
                self.isAnimating = false
            }
        }
    }
}
