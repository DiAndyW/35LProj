//
//  AnalyticsView.swift
//  uclamoods
//
//  Created by Assistant on 6/3/25.
//

import SwiftUI
import CoreLocation

struct SocialAnalyticsView: View {
    @StateObject private var analyticsService = AnalyticsService()
    @StateObject private var locationManager = LocationManager()
    @State private var refreshID = UUID()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if analyticsService.isLoading {
                loadingView
            } else if let errorMessage = analyticsService.errorMessage {
                errorView(errorMessage)
            } else if let data = analyticsService.communityData {
                analyticsContent(data)
            } else {
                emptyStateView
            }
        }
        .onAppear {
            loadAnalytics()
        }
        .refreshable {
            refreshID = UUID()
            loadAnalytics()
        }
        .id(refreshID)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading community insights...")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load analytics")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Try Again") {
                loadAnalytics()
            }
            .font(.custom("Georgia", size: 16))
            .fontWeight(.medium)
            .foregroundColor(.black)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(25)
        }
        .padding()
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No data available")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Check back later for community insights")
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Analytics Content
    private func analyticsContent(_ data: CommunityAnalyticsData) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                analyticsHeader
                
                // Global Community Stats
                globalStatsSection(data.overallStats)
                
                // Local Area Insights (if available)
                if let localStats = data.localStats,
                   let comparison = data.globalComparison {
                    localInsightsSection(localStats, comparison)
                }
                
                // Emotion Breakdown Chart
                emotionBreakdownSection(data.overallStats.emotionBreakdown)
                
                // Activity & Trends
//                if let trends = data.trends {
//                    trendsSection(trends)
//                }
                
                // Engagement Metrics
                engagementSection(data.overallStats)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Header
    private var analyticsHeader: some View {
        VStack(spacing: 8) {
            Text("Community Insights")
                .font(.custom("Georgia", size: 28))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("How's everyone feeling?")
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Global Stats Section
    private func globalStatsSection(_ stats: MapStatsData) -> some View {
        AnalyticsCard(
            title: "Global Community Vibe",
            icon: "globe.americas.fill",
            iconColor: .blue
        ) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: getVibeIcon(from: stats.emotionBreakdown))
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text(getOverallVibe(from: stats.emotionBreakdown))
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Mood Shares")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(stats.totalPosts)")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Daily Average")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(String(format: "%.1f", stats.postsPerDay))")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - Local Insights Section
    private func localInsightsSection(_ localStats: MapStatsData, _ comparison: GlobalComparison) -> some View {
        AnalyticsCard(
            title: "Your Area",
            icon: "location.circle.fill",
            iconColor: .orange
        ) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: getEmotionIcon(comparison.localDominantEmotion))
                        .foregroundColor(EmotionColorMap.getColor(for: comparison.localDominantEmotion))
                        .font(.title2)
                    
                    Text("Local Vibe: \(comparison.localDominantEmotion)")
                        .font(.custom("Georgia", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Text(comparison.comparisonText)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Emotion Breakdown Section
    private func emotionBreakdownSection(_ emotions: [String: Int]) -> some View {
        AnalyticsCard(
            title: "Top Emotions",
            icon: "heart.circle.fill",
            iconColor: .pink
        ) {
            VStack(spacing: 8) {
                ForEach(getTopEmotions(emotions), id: \.name) { emotion in
                    EmotionBarView(
                        name: emotion.name,
                        percentage: emotion.percentage,
                        color: EmotionColorMap.getColor(for: emotion.name)
                    )
                }
            }
        }
    }
    
    // MARK: - Trends Section
    private func trendsSection(_ trends: TrendData) -> some View {
        AnalyticsCard(
            title: "Trending",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .green
        ) {
            VStack(spacing: 12) {
                if !trends.trendingHashtags.isEmpty {
                    TrendRowView(
                        icon: "number",
                        title: "Trending Topics",
                        value: trends.trendingHashtags.prefix(2).joined(separator: ", ")
                    )
                }
                
                if !trends.popularLocations.isEmpty {
                    TrendRowView(
                        icon: "mappin.circle",
                        title: "Popular Spots",
                        value: trends.popularLocations.first ?? "N/A"
                    )
                }
                
                TrendRowView(
                    icon: "arrow.up.circle",
                    title: "Weekly Growth",
                    value: "+\(String(format: "%.1f", trends.weeklyGrowth))%"
                )
            }
        }
    }
    
    // MARK: - Engagement Section
    private func engagementSection(_ stats: MapStatsData) -> some View {
        AnalyticsCard(
            title: "Community Activity",
            icon: "person.3.fill",
            iconColor: .purple
        ) {
            HStack(spacing: 20) {
                StatBubble(
                    value: "\(stats.totalPosts)",
                    label: "Posts",
                    color: .blue
                )
                
                StatBubble(
                    value: "\(stats.emotionBreakdown.count)",
                    label: "Emotions",
                    color: .orange
                )
                
                StatBubble(
                    value: String(format: "%.0f", stats.postsPerDay * 7),
                    label: "Weekly",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadAnalytics() {
        locationManager.requestLocationAccessIfNeeded()
        
        Task {
            await analyticsService.fetchCommunityAnalytics(
                userLocation: locationManager.userCoordinates
            )
        }
    }
    
    private func getOverallVibe(from emotions: [String: Int]) -> String {
        let topEmotion = emotions.max { $0.value < $1.value }?.key ?? "Neutral"
        
        // Categorize emotions into vibes
        let positiveEmotions = ["Happy", "Joyful", "Excited", "Grateful", "Blissful", "Euphoric", "Thrilled"]
        let calmEmotions = ["Calm", "Relaxed", "Serene", "Content", "Peaceful"]
        let energeticEmotions = ["Energized", "Motivated", "Inspired", "Exhilarated"]
        
        if positiveEmotions.contains(topEmotion) {
            return "Generally Positive"
        } else if calmEmotions.contains(topEmotion) {
            return "Peaceful & Calm"
        } else if energeticEmotions.contains(topEmotion) {
            return "High Energy"
        } else {
            return "Mixed Emotions"
        }
    }
    
    private func getVibeIcon(from emotions: [String: Int]) -> String {
        let vibe = getOverallVibe(from: emotions)
        switch vibe {
        case "Generally Positive":
            return "sun.max.fill"
        case "Peaceful & Calm":
            return "leaf.fill"
        case "High Energy":
            return "bolt.fill"
        default:
            return "cloud.sun.fill"
        }
    }
    
    private func getEmotionIcon(_ emotion: String) -> String {
        // Map emotions to SF Symbols
        switch emotion.lowercased() {
        case "happy", "joyful", "excited":
            return "face.smiling.fill"
        case "calm", "relaxed", "serene":
            return "leaf.fill"
        case "energized", "motivated":
            return "bolt.fill"
        case "grateful", "blessed":
            return "heart.fill"
        default:
            return "circle.fill"
        }
    }
    
    private func getTopEmotions(_ emotions: [String: Int]) -> [(name: String, percentage: Int)] {
        let total = emotions.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        return emotions
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (name: $0.key, percentage: Int(Double($0.value) / Double(total) * 100)) }
    }
}

// MARK: - Supporting Views

struct AnalyticsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                
                Text(title)
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EmotionBarView: View {
    let name: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(percentage)%")
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 35, alignment: .trailing)
        }
    }
}

struct TrendRowView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            Text(title)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.custom("Georgia", size: 14))
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct StatBubble: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        SocialAnalyticsView()
            .preferredColorScheme(.dark)
    }
}
