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
struct BasicEmotionData: Codable {
    let name: String
    let attributes: EmotionAttributesData
}

// MARK: - Top Mood within UserProfileData
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

// MARK: - Average Mood within WeeklySummaryData
struct AverageMoodData: Codable {
    let averageAttributes: EmotionAttributesData
    let totalCheckins: Int
    let topEmotion: String?
    let topEmotionCount: Int
}

// MARK: - Weekly Summary
struct WeeklySummaryData: Codable {
    let weeklyCheckinsCount: Int
    let averageMoodForWeek: AverageMoodData
}

// MARK: - Main User Profile Data
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
