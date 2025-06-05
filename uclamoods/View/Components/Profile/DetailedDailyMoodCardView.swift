//
//  DetailedDailyMoodCardView.swift
//  uclamoods
//
//  Created by David Sun on 6/4/25.
//
import SwiftUI

struct DetailedDailyMoodCardView: View {
    let daySummary: MoodDaySummary
    
    private var accentColor: Color {
        return EmotionColorMap.getColor(for: daySummary.topEmotion ?? "Neutral")
    }

    
    var body: some View {
        
        let averageEmotion = Emotion(
            name: "Average",
            color: ColorData.calculateMoodColor(pleasantness: daySummary.averageAttributes.pleasantness, intensity: daySummary.averageAttributes.intensity) ?? .gray,
            description: "Average mood attributes for the period.",
            pleasantness: daySummary.averageAttributes.pleasantness ?? 0.5,
            intensity: daySummary.averageAttributes.intensity ?? 0.5,
            control: daySummary.averageAttributes.control ?? 0.5,
            clarity: daySummary.averageAttributes.clarity ?? 0.5
        )
        
        VStack(spacing: 6){
            VStack(alignment: .leading, spacing: 10) {
                Text(daySummary.dayOfWeek)
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(averageEmotion.color)
                
                Divider().background(accentColor.opacity(0.5))
                
                HStack {
                    Text("Total Check-ins:")
                        .font(.custom("Chivo", size: 14))
                    Text("\(daySummary.totalCheckins)")
                        .font(.custom("Chivo", size: 14))
                    Spacer()
                }
                .foregroundColor(.white.opacity(0.9))
                
                if let topEmotion = daySummary.topEmotion, daySummary.topEmotionCount > 0 {
                    HStack {
                        Text("Top Emotion:")
                            .font(.custom("Chivo", size: 14))
                        Text("\(topEmotion) (\(daySummary.topEmotionCount)x)")
                            .font(.custom("Chivo", size: 14))
                            .foregroundColor(EmotionColorMap.getColor(for: topEmotion))
                        Spacer()
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                
                Text("Average Attributes:")
                    .font(.custom("Chivo", size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 5)
            }
            if daySummary.totalCheckins > 0 {
                EmotionRadarChartView(emotion: averageEmotion, showText: true)
                    .frame(width: 150, height: 150)
                    .padding(10)
            }else{
                Text("No Data!")
                    .font(.custom("Chivo", size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(averageEmotion.color.opacity(0.6), lineWidth: 1.5)
        )
    }
}
