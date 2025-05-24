import SwiftUI

// Updated EmotionCircleView
struct EmotionCircleView: View {
    let emotion: Emotion
    let isSelected: Bool
    @Binding var isPressing: Bool  // New binding for press animation
    @State private var glowOpacity: Double = 0.0
    
    // For preview only
    init(emotion: Emotion, isSelected: Bool, isPressing: Binding<Bool> = .constant(false)) {
        self.emotion = emotion
        self.isSelected = isSelected
        self._isPressing = isPressing
    }
    
    var body: some View {
        ZStack {
            // Glow layer (when selected)
            if isSelected {
                Circle()
                    .fill(emotion.color)
                    .scaleEffect(1.2 * (isPressing ? 0.95 : 1.0))
                    .opacity(glowOpacity)
                    .blur(radius: 12)
                    .padding(.top, 10)
            }
            
            // Main circle
            Circle()
                .fill(emotion.color)
                .shadow(color: emotion.color.opacity(0.6), radius: isSelected ? 10 : 3, x: 0, y: isSelected ? 5 : 2)
                .scaleEffect((isSelected ? 1.0 : 0.8) * (isPressing ? 0.95 : 1.0))
                .blur(radius: 8)
            
            // Text
            Text(emotion.name)
                .font(.custom("Georgia", size: 24))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(4)
                .scaleEffect((isSelected ? 1.0 : 0.9) * (isPressing ? 0.95 : 1.0))
                .opacity(isSelected ? 1.0 : 0.7)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)
        .onAppear {
            if isSelected {
                startGlowAnimation()
            }
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                startGlowAnimation()
            } else {
                glowOpacity = 0.0
            }
        }
    }
    
    private func startGlowAnimation() {
        // Reset to start state
        glowOpacity = 0.0
        
        // Start the continuous pulsing animation
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.5
        }
    }
}

struct EmotionCircleView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionCircleView(
            emotion: EmotionDataProvider.highEnergyEmotions[0],
            isSelected: true
        )
        .frame(width: 150, height: 150)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
