//
//  Summary.swift
//  uclamoods
//
//  Created by David Sun on 6/1/25.
//

import Foundation

struct EmotionAttributesData: Codable {
    let pleasantness: Double
    let intensity: Double
    let control: Double
    let clarity: Double
}

// MARK: - Reusable Basic Emotion Structure
// Represents an emotion with its name and attributes.
struct BasicEmotionData: Codable {
    let name: String
    let attributes: EmotionAttributesData
}

// MARK: - Top Mood within UserProfileData
// 'topMood' in the JSON has 'name' and 'attributes' at the same level as 'count',
// so it's slightly different from just BasicEmotionData + count.
// The previous TopMoodData structure was already direct.
struct TopMoodData: Codable {
    let name: String
    let count: Int
    let attributes: EmotionAttributesData
}

// MARK: - Recent Checkin Item
struct RecentCheckinData: Codable, Identifiable {
    let id: String
    let emotion: BasicEmotionData
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case emotion, timestamp
    }
}

// MARK: - Weekly Top Mood within WeeklySummaryData
struct WeeklyTopMoodData: Codable {
    let name: String
    let count: Int
}

// MARK: - Average Mood within WeeklySummaryData
// Matches the structure of averageMoodForWeek in the JS backend
struct AverageMoodData: Codable {
    let averageAttributes: EmotionAttributesData
    let totalCheckins: Int
    let topEmotion: String?
    let topEmotionCount: Int
}

// MARK: - Weekly Summary
struct WeeklySummaryData: Codable {
    let weeklyCheckinsCount: Int
    let weeklyTopMood: WeeklyTopMoodData?
    let averageMoodForWeek: AverageMoodData
}

// MARK: - Main User Profile Data (the "data" object)
// This remains a dedicated struct for this specific API response.
struct UserSummaryData: Codable {
    let username: String
    let email: String
    let profilePicture: String?
    let totalCheckins: Int
    let checkinStreak: Int
    let topMood: TopMoodData?
    let recentCheckins: [RecentCheckinData]
    let weeklySummary: WeeklySummaryData
}

// MARK: - Root Response Object
struct UserSummary: Codable {
    let success: Bool
    let data: UserSummaryData
}
