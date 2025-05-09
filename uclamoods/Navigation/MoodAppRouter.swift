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
    
    // Customizable durations
    let fadeOutDuration: Double = 0.4
    let fadeInDuration: Double = 0.5
    let transitionStyle: TransitionStyle = .bubbleExpand
    
    func navigateToEmotionSelection(energyLevel: EmotionDataProvider.EnergyLevel, from originPoint: CGPoint = .zero) {
        transitionOrigin = originPoint
        performTransition(to: .emotionSelection(energyLevel: energyLevel))
    }
    
    func navigateBack(from originPoint: CGPoint = .zero) {
        transitionOrigin = originPoint
        performTransition(to: .energySelection)
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
