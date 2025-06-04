//
//  ProfileSummarySection.swift
//  uclamoods
//
//  Created by David Sun on 6/4/25.
//
import SwiftUI

struct ProfileSummarySectionView: View {
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    let summary: UserSummary?
    let isLoading: Bool
    let loadingError: String?
    
    init(summary: UserSummary?, isLoading: Bool, loadingError: String?) {
        self.summary = summary
        self.isLoading = isLoading
        self.loadingError = loadingError
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if isLoading {
                ProgressView("Loading weekly summary...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if let error = loadingError {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("Failed to load summary")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
            } else if let currentSummaryData = summary?.data {
                let weeklySummary = currentSummaryData.weeklySummary
                let avgPleasantness = weeklySummary.averageMoodForWeek.averageAttributes.pleasantness
                let avgIntensity = weeklySummary.averageMoodForWeek.averageAttributes.intensity
                let avgControl = weeklySummary.averageMoodForWeek.averageAttributes.control
                let avgClarity = weeklySummary.averageMoodForWeek.averageAttributes.clarity
                
                let averageEmotion = Emotion(
                    name: weeklySummary.averageMoodForWeek.topEmotion ?? "Average",
                    color: ColorData.calculateMoodColor(pleasantness: avgPleasantness, intensity: avgIntensity) ?? .gray,
                    description: "Average mood for the week.",
                    pleasantness: avgPleasantness,
                    intensity: avgIntensity,
                    control: avgControl,
                    clarity: avgClarity
                )
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Average Attributes")
                            .font(.custom("Georgia", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    
                    EmotionRadarChartView(emotion: averageEmotion)
                        .offset(y: -10)
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(averageEmotion.color.opacity(0.6), lineWidth: 2) // Border with emotion color.
                )
                
                // Grid for displaying weekly statistics.
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    WeekStatCard(
                        title: "Top Emotion",
                        value: weeklySummary.weeklyTopMood?.name ?? "N/A"
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EmotionDataProvider.getEmotion(byName: weeklySummary.weeklyTopMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                    )
                    
                    WeekStatCard(
                        title: "Check-ins",
                        value: "\(weeklySummary.weeklyCheckinsCount)"
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EmotionDataProvider.getEmotion(byName: weeklySummary.weeklyTopMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                    )
                }
            } else {
                Text("No summary data available for this week.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
    }
}
