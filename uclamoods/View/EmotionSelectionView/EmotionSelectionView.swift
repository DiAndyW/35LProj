import SwiftUI

struct EmotionSelectionView: View {
    // State variable to track the ID of the currently centered emotion
    @State private var selectedEmotionID: Emotion.ID?
    @State private var navigateToNextScreen = false
    
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
    
    var body: some View {
        GeometryReader { geometry in
            let dynamicCircleSize = min(geometry.size.width * 0.5, geometry.size.height * 0.3)
            
            ZStack {
//                // Background
                Color.black.edgesIgnoringSafeArea(.all)
//                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Description appears first (above)
                    EmotionDescriptionView(
                        emotion: selectedEmotion ?? EmotionDataProvider.defaultEmotion
                    )
                    .padding(.horizontal)
                    .frame(height: 120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id(selectedEmotion?.id ?? EmotionDataProvider.defaultEmotion.id)
                    .padding(.bottom, 40)
                    .padding(.top, 20)
                    
                    // Radar chart for emotion dimensions
                    EmotionRadarChartView(
                        emotion: selectedEmotion ?? EmotionDataProvider.defaultEmotion
                    )
                    .frame(height: 200)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id((selectedEmotion?.id ?? EmotionDataProvider.defaultEmotion.id).uuidString + "-chart")
                    
                    
                    // Scrollable emotion circles at bottom
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: horizontalSpacing) {
                            ForEach(emotions) { emotion in
                                EmotionCircleView(
                                    emotion: emotion,
                                    isSelected: selectedEmotionID == emotion.id
                                )
                                .padding(.bottom, 30)
                                .frame(width: dynamicCircleSize + 10, height: dynamicCircleSize + 10)
                                .id(emotion.id)
                                .onTapGesture {
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
                    .safeAreaPadding(.horizontal, (geometry.size.width - dynamicCircleSize) / 2)
                    .scrollPosition(id: $selectedEmotionID, anchor: .center)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedEmotionID)
                    
//                    NavigationLink(
//                        destination: EmotionDetailView(emotion: selectedEmotion),
//                        isActive: $navigateToNextScreen,
//                        label: { EmptyView() }
//                    )
                    
                    // Bottom oval button with the selected emotion's color
                    BottomOvalButton(
                        buttonText: "→",
                        action: {
                            // Action when button is tapped
                            navigateToNextScreen = true
                        },
                        emotion: selectedEmotion ?? EmotionDataProvider.defaultEmotion
                    )
                }
                }
                .onAppear {
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
