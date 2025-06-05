import SwiftUI
import UIKit

struct EmotionSelectionView: View {
    @EnvironmentObject private var router: MoodAppRouter
    // State variable to track the ID of the currently centered emotion
    @State private var selectedBlobPosition: CGPoint = .zero
    @State private var selectedEmotionID: Emotion.ID?
    @State private var navigateToNextScreen = false
    @State private var previousEmotionID: Emotion.ID? = nil
    @State private var isInitialAppearance = true
    
    @State private var pressingEmotionID: Emotion.ID? = nil
    
    let energyLevel: EmotionDataProvider.EnergyLevel
    
    // List of emotions to display
    let emotions: [Emotion]
    
    // Layout parameters
    let horizontalSpacing: CGFloat
    
    // Initializer with defaults
    init(
        energyLevel: EmotionDataProvider.EnergyLevel = .high,
        horizontalSpacing: CGFloat = 0
    ) {
        self.energyLevel = energyLevel
        self.horizontalSpacing = horizontalSpacing
        
        // Set the energy level in the provider
        EmotionDataProvider.selectedEnergyLevel = energyLevel
        
        // Get appropriate emotions for the selected energy level
        self.emotions = EmotionDataProvider.getEmotionsForCurrentEnergyLevel()
    }
    
    // Computed property to get the full selected emotion object
    private var selectedEmotion: Emotion? {
        guard let selectedEmotionID = selectedEmotionID else { return nil }
        return emotions.first { $0.id == selectedEmotionID }
    }
    
    // Helper function for haptic feedback
    private func generateHapticFeedback(for emotionID: Emotion.ID?) {
        // Skip feedback on initial appearance
        guard !isInitialAppearance else {
            isInitialAppearance = false
            return
        }
        
        // Only generate haptic feedback when the emotion actually changes
        if previousEmotionID != emotionID {
            // Standard selection feedback
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
            
            // Update previous emotion ID for next comparison
            previousEmotionID = emotionID
        }
    }
    
    private func navigateToCompleteCheckIn(with emotion: Emotion) {
        // Capture the position of the selected blob
        if let frame = getBlobFrame(for: emotion) {
            selectedBlobPosition = CGPoint(
                x: frame.midX,
                y: frame.midY
            )
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Navigate with the blob transition using the new router
        router.setMoodFlowTransitionStyle(.blobToTop(emotion: emotion))
        router.navigateToCompleteCheckIn(emotion: emotion)
    }
    
    // Helper to get blob frame (you'll need to implement this)
    private func getBlobFrame(for emotion: Emotion) -> CGRect? {
        // This would require using GeometryReader or preference keys
        // to capture the actual frame of the blob
        // For now, return an approximate position
        return nil
    }
    
    private func triggerPressAnimation(for emotionID: Emotion.ID, then action: @escaping () -> Void) {
        // Set the pressing state
        pressingEmotionID = emotionID
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressingEmotionID = nil
            
            // Execute the action after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                action()
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let dynamicCircleSize = min(geometry.size.width * 0.5, availableHeight * 0.25)
            
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top section with flexible spacing
                    Spacer()
                        .frame(height: availableHeight * 0.10) // 5% of height as top spacing
                    
                    // Description below the chart
                    EmotionDescriptionView(
                        emotion: selectedEmotion ?? EmotionDataProvider.defaultEmotion
                    )
                    .padding(.horizontal)
                    .frame(height: availableHeight * 0.15) // 15% of screen height
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id(selectedEmotion?.id ?? EmotionDataProvider.defaultEmotion.id)
                    
                    Spacer()
                        .frame(height: availableHeight * 0.10)
                    
                    
                    // Radar chart moved to the top for better visibility
                    EmotionRadarChartView(
                        emotion: selectedEmotion ?? EmotionDataProvider.defaultEmotion
                    )
                    .padding(16)
                    .frame(height: availableHeight * 0.3) // 30% of screen height
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id((selectedEmotion?.id ?? EmotionDataProvider.defaultEmotion.id).uuidString + "-chart")
                    
                    
                    // Flexible spacing that grows/shrinks based on available space
                    Spacer(minLength: availableHeight * 0.02)
                    
                    // Scrollable emotion circles
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(emotions) { emotion in
                                ZStack {
                                    FloatingBlobButton(
                                        text: emotion.name,
                                        morphSpeed: 1.0,
                                        floatSpeed: 0.75,
                                        colorShiftSpeed: 2.0,
                                        colorPool: [emotion.color],
                                        isSelected: selectedEmotionID == emotion.id,
                                        isPressing: Binding(
                                            get: { pressingEmotionID == emotion.id },
                                            set: { _ in }
                                        ),
                                        action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                            impactFeedback.prepare()
                                            impactFeedback.impactOccurred()
                                            
                                            triggerPressAnimation(for: emotion.id) {
                                                if selectedEmotionID == emotion.id {
                                                    // If already selected, navigate to complete check-in
                                                    navigateToCompleteCheckIn(with: emotion)
                                                } else {
                                                    // Otherwise, select this emotion
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        selectedEmotionID = emotion.id
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .scaleEffect(pressingEmotionID == emotion.id ? 0.95 : 1.0)
                                    .animation(.easeInOut(duration: 0.1), value: pressingEmotionID)
                                }
                                .frame(width: dynamicCircleSize, height: dynamicCircleSize)
                                .padding(.vertical, 50)
                                .id(emotion.id)
                                .onTapGesture {
                                    // Add haptic feedback for tap selection

                                }
                                .scrollTransition { effect, phase in
                                    effect
                                        .scaleEffect(phase.isIdentity ? 1 : 0.8)
                                        .offset(y: EmotionSelectionView.transitionOffset(for: phase))
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    
                    .scrollTargetBehavior(.viewAligned)
                    .defaultScrollAnchor(.center)
                    .safeAreaPadding(.horizontal, (geometry.size.width - dynamicCircleSize) / 2)
                    .scrollPosition(id: $selectedEmotionID, anchor: .center)
                    .onChange(of: selectedEmotionID) { _, newID in
                        // Add haptic feedback for scroll selection
                        generateHapticFeedback(for: newID)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.9), value: selectedEmotionID)
                    .frame(height: dynamicCircleSize + 20)
                    
                    // Bottom section with flexible spacing
                    Spacer()
                        .frame(height: availableHeight * 0.02)
                    
                    // Bottom oval button with the selected emotion's color
                    BottomOvalShape(
                        emotion: selectedEmotion ?? EmotionDataProvider.defaultEmotion
                    )
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom)
                
                // Back button with absolute positioning - UPDATED FOR NEW ROUTER
                VStack {
                    HStack {
                        Button(action: {
                            // Add haptic feedback for back button press
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred()
                            
                            // Use the new mood flow back navigation
                            router.navigateBackInMoodFlow(from: CGPoint(x: UIScreen.main.bounds.size.width * 0.1, y: UIScreen.main.bounds.size.height * 0.0))
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 25)
                        .padding(.top, -availableHeight * 0.02)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    // Left side label - "less pleasant"
                    HStack(alignment: .bottom){
                        Text("← Unpleasant")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 100)
                            .padding(.leading, 5)
                        Spacer()
                        Text("Pleasant →")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 100)
                            .padding(.trailing, 5)
                    }
                    .padding(.top, availableHeight * 0.15)
                    
                    Spacer()
                }
            }
            .onAppear {
                isInitialAppearance = true
                selectedEmotionID = EmotionDataProvider.defaultEmotion.id
            }
        }
    }
    
    // Static helper for transition offset calculation
    static func transitionOffset(for phase: ScrollTransitionPhase) -> Double {
        switch phase {
        case .topLeading:
            return 50
        case .identity:
            return 0
        case .bottomTrailing:
            return 50
        }
    }
}

struct UpdatedEmotionSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionSelectionView()
            .preferredColorScheme(.dark)
            .environmentObject(MoodAppRouter())
    }
}
