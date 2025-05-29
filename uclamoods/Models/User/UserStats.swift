import Foundation
import SwiftUI

struct UserStats: Identifiable {
    let id = UUID()
    let totalCheckIns: Int
    let currentStreak: Int
    let topEmotion: String
    let weeklyCheckIns: Int
    let averageEnergy: String
    let longestStreak: Int
    
    static let sample = UserStats(
        totalCheckIns: 127,
        currentStreak: 8,
        topEmotion: "Happy",
        weeklyCheckIns: 5,
        averageEnergy: "High",
        longestStreak: 15
    )
}

// MARK: - Recent Activity Model
struct RecentActivity: Identifiable {
    let id = UUID()
    let emotion: String
    let time: String
    let color: Color
    let timestamp: Date
    
    static let sampleActivities = [
        RecentActivity(
            emotion: "Happy",
            time: "2h ago",
            color: .yellow,
            timestamp: Date().addingTimeInterval(-7200)
        ),
        RecentActivity(
            emotion: "Calm",
            time: "5h ago",
            color: .blue,
            timestamp: Date().addingTimeInterval(-18000)
        ),
        RecentActivity(
            emotion: "Excited",
            time: "1d ago",
            color: .orange,
            timestamp: Date().addingTimeInterval(-86400)
        )
    ]
}

// MARK: - Weekly Stats Model
struct WeeklyStats: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let date: Date
    
    static let sampleStats = [
        WeeklyStats(
            title: "Most Frequent Mood",
            value: "Happy",
            subtitle: "Appeared 5 times this week",
            date: Date()
        ),
        WeeklyStats(
            title: "Average Energy",
            value: "High",
            subtitle: "Based on 7 check-ins",
            date: Date()
        ),
        WeeklyStats(
            title: "Best Day",
            value: "Wednesday",
            subtitle: "Most positive emotions",
            date: Date()
        )
    ]
} 
