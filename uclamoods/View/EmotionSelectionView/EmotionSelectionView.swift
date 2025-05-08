import SwiftUI
import UIKit

struct EmotionSelectionView: View {
    // State variable to track the ID of the currently centered emotion
    @State private var selectedEmotionID: Emotion.ID?
    @State private var navigateToNextScreen = false
    @State private var previousEmotionID: Emotion.ID? = nil
    @State private var isInitialAppearance = true
    
    // Environment variable to handle dismissal
    @Environment(\.dismiss) private var dismiss
    
    // List of emotions to display
    let emotions: [Emotion]
    
    // Layout parameters
    let horizontalSpacing: CGFloat
    
    // Initializer with defaults
    init(
        emotions: [Emotion] = EmotionDataProvider.highEnergyEmotions,
        horizontalSpacing: CGFloat = 0
    ) {
        self.emotions = emotions
        self.horizontalSpacing = horizontalSpacing
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
                    .frame(height: availableHeight * 0.3) // 30% of screen height
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id((selectedEmotion?.id ?? EmotionDataProvider.defaultEmotion.id).uuidString + "-chart")
                    
                    
                    // Flexible spacing that grows/shrinks based on available space
                    Spacer(minLength: availableHeight * 0.02)
                    
                    // Scrollable emotion circles
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(emotions) { emotion in
                                EmotionCircleView(
                                    emotion: emotion,
                                    isSelected: selectedEmotionID == emotion.id
                                )
                                .frame(width: dynamicCircleSize, height: dynamicCircleSize)
                                .padding(.vertical, 30)
                                .id(emotion.id)
                                .onTapGesture {
                                    // Add haptic feedback for tap selection
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                    impactFeedback.prepare()
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedEmotionID = emotion.id
                                    }
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
                
                // Back button with absolute positioning
                VStack {
                    HStack {
                        Button(action: {
                            // Add haptic feedback for back button press
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred()
                            
                            // Dismiss the view
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 25)
                        .padding(.top, availableHeight * 0.03)
                        
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
}

struct EmotionScrollView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionSelectionView()
            .preferredColorScheme(.dark)
    }
}

struct CustomScrollTargetBehavior: ScrollTargetBehavior {
    // Lower values make it more sensitive
    let sensitivityFactor: CGFloat
    
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        ViewAlignedScrollTargetBehavior().updateTarget(&target, context: context)
        // Make the scroll target reach its destination with less movement
        let distance = target.rect.minX - context.originalTarget.rect.minX
        target.rect.origin.x = context.originalTarget.rect.minX + (distance * sensitivityFactor)
    }
}
