import SwiftUI

struct WeekStatCard: View {
    let title: String
    let value: String
    
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
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
