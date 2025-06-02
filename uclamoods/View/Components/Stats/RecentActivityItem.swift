import SwiftUI

struct RecentActivityItem: View {    
    let emotion: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("Felt \(emotion)")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(time)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}


//#Preview {
//    RecentActivityItem(activity: RecentActivity.sampleActivities[0])
//        .padding()
//        .background(Color.black)
//} 
