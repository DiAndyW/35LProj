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
            Text("Your Morii")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if isLoading {
                ProgressView("Loading weekly summary...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if let currentSummaryData = summary?.data {
                let avgPleasantness = currentSummaryData.topMood?.attributes.pleasantness
                let avgIntensity = currentSummaryData.topMood?.attributes.intensity
                let avgControl = currentSummaryData.topMood?.attributes.control
                let avgClarity = currentSummaryData.topMood?.attributes.clarity
                
                let averageEmotion = Emotion(
                    name: currentSummaryData.topMood?.name ?? "Average",
                    color: ColorData.calculateMoodColor(pleasantness: avgPleasantness, intensity: avgIntensity) ?? .gray,
                    description: "Average mood for the week.",
                    pleasantness: avgPleasantness ?? 50,
                    intensity: avgIntensity ?? 50,
                    control: avgControl ?? 50,
                    clarity: avgClarity ?? 50
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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    
                    VStack(spacing: 8) {
                        Text(currentSummaryData.topMood?.name ?? "N/A")
                            .font(.custom("Georgia", size: 20))
                            .scaledToFit()
                            .fontWeight(.bold)
                            .foregroundColor(EmotionDataProvider.getEmotion(byName: currentSummaryData.topMood?.name ?? "Neutral")?.color ?? Color.pink)
                        
                        Text("Top Mood")
                            .font(.custom("Georgia", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EmotionDataProvider.getEmotion(byName: currentSummaryData.topMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                    )
                    
                    VStack(spacing: 8) {
                        Text("\(currentSummaryData.totalCheckins)")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(EmotionDataProvider.getEmotion(byName: currentSummaryData.topMood?.name ?? "Neutral")?.color ?? Color.pink)
                        
                        Text("Check-Ins")
                            .font(.custom("Georgia", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EmotionDataProvider.getEmotion(byName: currentSummaryData.topMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                    )
                    
                    VStack(spacing: 8) {
                        Text("\(currentSummaryData.checkinStreak)")
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(EmotionDataProvider.getEmotion(byName: currentSummaryData.topMood?.name ?? "Neutral")?.color ?? Color.pink)
                        
                        Text("Streak")
                            .font(.custom("Georgia", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EmotionDataProvider.getEmotion(byName: currentSummaryData.topMood?.name ?? "Neutral")?.color.opacity(0.6) ?? Color.white.opacity(0.6), lineWidth: 2)
                    )
                    
                }
            } else {
                Text("No summary data available.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
    }
}
