import SwiftUI

struct WeekStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.custom("Georgia", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.pink)
            
            Text(title)
                .font(.custom("Georgia", size: 14))
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
