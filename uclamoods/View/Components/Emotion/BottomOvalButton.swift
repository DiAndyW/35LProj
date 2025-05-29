import SwiftUI

struct BottomOvalShape: View {
    var emotion: Emotion
    
    var body: some View {
        VStack {
            Spacer() // Pushes the shape to the bottom
            
            ZStack{
                // The shape itself without button functionality
                HalfOvalShape()
                    .fill(emotion.color)
                    .shadow(color: emotion.color.opacity(0.4), radius: 10, x: 0, y: -4)
                    .frame(height: 120) // Setting a specific height to preserve size
                    .frame(maxWidth: .infinity)
                    .blur(radius: 5)
//                HalfOvalShape()
//                    .fill(emotion.color)
//                    .scaleEffect(1.6)
//                    .opacity(0.2)
//                    .shadow(color: emotion.color.opacity(0.4), radius: 10, x: 0, y: -4)
//                    .frame(height: 120) // Setting a specific height to preserve size
//                    .frame(maxWidth: .infinity)
//                    .blur(radius: 35)
            }
            
        }
        .padding(.top, -20)
        .edgesIgnoringSafeArea(.bottom) // Extends to the bottom edge of the screen
    }
}

// Custom shape for the half-oval
struct HalfOvalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from the bottom left corner
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        // Draw the left side straight up to the height where the oval starts
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.5))
        
        // Draw the top semi-oval
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control1: CGPoint(x: rect.width * 0.3, y: 0),
            control2: CGPoint(x: rect.width * 0.7, y: 0)
        )
        
        // Draw the right side straight down
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}
