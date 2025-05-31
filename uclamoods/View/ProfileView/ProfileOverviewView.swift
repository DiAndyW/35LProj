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
                    .font(.custom("Georgia", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    WeekStatCard(title: "Check-ins", value: "5", subtitle: "This week")
                    WeekStatCard(title: "Avg Energy", value: "High", subtitle: "↑ from last week")
                    WeekStatCard(title: "Top Emotion", value: "Happy", subtitle: "3 times")
                    WeekStatCard(title: "Streak", value: "\(stats.currentStreak) days", subtitle: "Keep it up!")
                }
            }
            
            // Recent activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.custom("Georgia", size: 20))
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
