import SwiftUI

struct EnergyCircleView: View {
    let title: String
    let color: Color
    let action: () -> Void
    let animationDuration: Double
    
    // Animation properties for offsets - these will be animated
    @State private var circle1Offset = CGPoint(x: -8, y: -8) // Initial position for circle 1
    @State private var circle2Offset = CGPoint(x: 5, y: 5)   // Initial position for circle 2
    
    // Timer to trigger animations periodically
    // We'll store the timer to manage its lifecycle (start/stop)
    @State private var animationTimer: Timer? = nil
    
    //let animationDuration = 1.0 // Duration of each movement animation

    var body: some View {
        Button(action: action) {
            ZStack {
                // First background circle
                Circle()
                    .fill(color.opacity(0.6))
                    .frame(width: 160, height: 160)
                    .offset(x: circle1Offset.x, y: circle1Offset.y)
                
                // Second background circle
                Circle()
                    .fill(color.opacity(0.7))
                    .frame(width: 155, height: 155)
                    .offset(x: circle2Offset.x, y: circle2Offset.y)
                
                // Main circle
                Circle()
                    .fill(color)
                    .frame(width: 150, height: 150)
                    .shadow(color: color.opacity(0.6), radius: 3, x: 0, y: 2)
                
                // Text
                VStack(spacing: 0) {
                    let components = title.components(separatedBy: "\n")
                    if components.count >= 2 {
                        Text(components[0])
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white) // Consider dynamic color based on circle color for contrast
                        
                        Text(components[1])
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white) // Same consideration for contrast
                    } else {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start animations when the view appears
            startBackgroundAnimations()
        }
        .onDisappear {
            // Clean up the timer when the view disappears to prevent memory leaks
            stopBackgroundAnimations()
        }
    }
    
    // Function to update circle offsets with animation
    private func animateCircleOffsets() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            // Generate new random positions for circle 1
            circle1Offset = CGPoint(
                x: CGFloat.random(in: -12...0), // Confined to a small area
                y: CGFloat.random(in: -12...0)
            )
            
            // Generate new random positions for circle 2
            circle2Offset = CGPoint(
                x: CGFloat.random(in: 0...12),  // Confined to a small area
                y: CGFloat.random(in: 0...12)
            )
        }
    }
    
    // Function to start and maintain animations
    private func startBackgroundAnimations() {
        // Invalidate any existing timer to avoid duplicates if onAppear is called multiple times
        stopBackgroundAnimations()
        
        // Perform the first animation immediately
        animateCircleOffsets()
        
        // Schedule a timer to repeatedly trigger animations
        // The timer interval is set to animationDuration, so the next animation
        // starts right after the current one finishes, creating continuous movement.
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
            animateCircleOffsets()
        }
    }
    
    // Function to stop the timer
    private func stopBackgroundAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// Example usage preview (remains the same)
struct EnergyCircleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Provides a background for the preview
            EnergyCircleView(
                title: "High Energy\nPleasant",
                color: .yellow,
                action: {},
                animationDuration: 1.0
            )
        }
    }
}
