import SwiftUI

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
