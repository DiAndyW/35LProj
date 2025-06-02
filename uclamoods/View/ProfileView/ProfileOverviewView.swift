//
//  ProfileOverviewView.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//
import SwiftUI

struct ProfileOverviewView: View {
    let stats: UserStats
    
    var body: some View {
        VStack(spacing: 20) {
            // This week summary
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                EmotionRadarChartView(emotion: EmotionDataProvider.highEnergyEmotions[0])
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    WeekStatCard(title: "Top Emotion", value: "Happy", subtitle: "3 times")
                    WeekStatCard(title: "Check-ins", value: "5", subtitle: "This week")
                }
            }
            
            // Recent activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    RecentActivityItem(emotion: "Happy", time: "2 hours ago", color: .yellow)
                    RecentActivityItem(emotion: "Excited", time: "Yesterday", color: .orange)
                    RecentActivityItem(emotion: "Calm", time: "2 days ago", color: .blue)
                }
            }
        }
    }
}
