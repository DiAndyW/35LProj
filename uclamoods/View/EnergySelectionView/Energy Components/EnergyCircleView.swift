import SwiftUI

struct EnergyCircleView: View {
    let word: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Main circle
                Circle()
                    .fill(color)
                    .shadow(color: color.opacity(0.6), radius: 3, x: 0, y: 2)
                
                // Text
                Text(word)
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(4)
            }
        }
        .buttonStyle(PlainButtonStyle()) // Removes default button styling
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())
    }
}
