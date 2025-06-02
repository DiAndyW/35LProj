//
//  SocialAnalyticsView.swift
//  uclamoods
//
//  Created by Yang Gao on 6/2/25.
//
import SwiftUI

// Data structure for social analytics
struct CommunityAnalytics {
    let overallCommunityVibe: String
    let vibeIcon: String // SF Symbol name
    let topEmotions: [(name: String, percentage: Int, icon: String)]
    
    let localAreaName: String
    let localDominantEmotion: String
    let localEmotionIcon: String
    let localComparisonText: String
    
    let moodSharesToday: Int
    let trendingTopic: String
    let popularLocation: String
}

// Sample static data
let sampleCommunityAnalytics = CommunityAnalytics(
    overallCommunityVibe: "Generally Optimistic",
    vibeIcon: "sun.max.fill",
    topEmotions: [
        (name: "Joyful", percentage: 40, icon: "face.smiling.fill"),
        (name: "Hopeful", percentage: 25, icon: "sparkles"),
        (name: "Calm", percentage: 15, icon: "wind")
    ],
    localAreaName: "Your City", // Replace with actual city later
    localDominantEmotion: "Creative",
    localEmotionIcon: "paintpalette.fill",
    localComparisonText: "Creativity is trending 20% higher here than globally!",
    moodSharesToday: 1742,
    trendingTopic: "#MindfulMoments",
    popularLocation: "Central Park"
)

import SwiftUI

struct AnalyticsView: View {
    // Use the static sample data
    let analyticsData = sampleCommunityAnalytics
    
    var body: some View {
        NavigationView { // Optional: if you want a title bar
            List {
                // Section 1: Overall Community Vibe
                Section(header: Text("Global Community Vibe")
                            .font(.headline)
                            .foregroundColor(.secondary)) {
                    HStack {
                        Image(systemName: analyticsData.vibeIcon)
                            .foregroundColor(.yellow)
                            .font(.title2)
                        Text(analyticsData.overallCommunityVibe)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 5)
                    
                    Text("Top Emotions:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                    
                    ForEach(analyticsData.topEmotions, id: \.name) { emotion in
                        HStack {
                            Image(systemName: emotion.icon)
                                .foregroundColor(Color.accentColor) // Or a specific color
                            Text("\(emotion.name): \(emotion.percentage)%")
                            Spacer()
                            // Simple bar representation (optional visual)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor.opacity(0.7))
                                .frame(width: CGFloat(emotion.percentage) * 2.0, height: 10) // Scale factor
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                // Section 2: Local Area Insights
                Section(header: Text("Insights for \(analyticsData.localAreaName)")
                            .font(.headline)
                            .foregroundColor(.secondary)) {
                    HStack {
                        Image(systemName: analyticsData.localEmotionIcon)
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("Local Dominant: \(analyticsData.localDominantEmotion)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 5)
                    
                    Text(analyticsData.localComparisonText)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 5)
                }
                
                // Section 3: Engagement & Trends
                Section(header: Text("Engagement & Trends")
                            .font(.headline)
                            .foregroundColor(.secondary)) {
                    InfoRow(icon: "paperplane.fill", iconColor: .blue, title: "Mood Shares Today", value: "\(analyticsData.moodSharesToday)")
                    InfoRow(icon: "number", iconColor: .green, title: "Trending Topic", value: analyticsData.trendingTopic)
                    InfoRow(icon: "mappin.and.ellipse", iconColor: .red, title: "Popular Location", value: analyticsData.popularLocation)
                }
            }
            .listStyle(InsetGroupedListStyle()) // Or PlainListStyle() depending on your app's theme
            .navigationTitle("Community Insights") // Title for the view
            // .environment(\.colorScheme, .dark) // If your app is always dark, for preview
        }
        // If your app has a consistent black background, the NavigationView and List will adapt.
        // Otherwise, you might want to embed this in a ZStack with your background color.
    }
}

// Helper View for consistent row styling in the last section
struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 25, alignment: .center)
            Text(title)
                .font(.callout)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SocialAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            // .preferredColorScheme(.dark) // Uncomment to preview in dark mode
    }
}
