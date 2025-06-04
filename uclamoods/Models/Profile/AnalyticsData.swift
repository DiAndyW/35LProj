//
//  AnalyticsData.swift
//  uclamoods
//
//  Created by David Sun on 6/4/25.
//

import Foundation

// MARK: - Main Analytics Response
struct MoodAnalyticsResponse: Codable {
    let success: Bool
    let data: AnalyticsData?
    let message: String? // For error messages
}

// MARK: - Analytics Data
struct AnalyticsData: Codable {
    let period: String
    let dateRange: DateRange
    let averageMoodForPeriod: MoodPeriodSummary
    let averageMoodByDayOfWeek: [MoodDaySummary]
    let averageMoodByActivity: MoodContextSummary
    let averageMoodByPeople: MoodContextSummary
}

// MARK: - Nested Structures
struct DateRange: Codable {
    let start: Date? // Decode as Date
    let end: Date?   // Decode as Date
}

struct MoodAttributes: Codable {
    let pleasantness: Double?
    let intensity: Double?
    let control: Double?
    let clarity: Double?
}

struct MoodPeriodSummary: Codable {
    let averageAttributes: MoodAttributes
    let totalCheckins: Int
    let topEmotion: String?
    let topEmotionCount: Int
}

struct MoodDaySummary: Codable {
    let dayOfWeek: String
    let dayNumber: Int
    let averageAttributes: MoodAttributes
    let totalCheckins: Int
    let topEmotion: String?
    let topEmotionCount: Int
}

struct MoodContext: Codable, Identifiable {
    let id: UUID = UUID() // Provides a default value for client-side Identifiable conformance.
                          // This will NOT be looked for in the JSON if excluded from CodingKeys.
    
    let activity: String?
    let people: String?
    let averageAttributes: MoodAttributes
    let totalCheckins: Int
    let topEmotion: String?
    let topEmotionCount: Int // Your backend sends 0 if null, so non-optional is fine
    let percentageOfTotal: Double
    
    var contextName: String? {
        return activity ?? people
    }
    
    // Explicitly define CodingKeys to control what's encoded/decoded from JSON.
    // 'id' is NOT listed here, so it will be ignored during JSON processing.
    enum CodingKeys: String, CodingKey {
        case activity, people
        case averageAttributes, totalCheckins, topEmotion, topEmotionCount, percentageOfTotal
    }
}

struct ContextSummaryData: Codable {
    let totalUniqueContexts: Int
    let totalCheckinsWithContext: Int
}

struct MoodContextSummary: Codable {
    let contexts: [MoodContext]
    let summary: ContextSummaryData
}

// Enum for time periods to ensure type safety
enum AnalyticsPeriod: String, CaseIterable {
    case week, month, threeMonths = "3months", year, all
    
    var queryValue: String {
        return self.rawValue
    }
}
