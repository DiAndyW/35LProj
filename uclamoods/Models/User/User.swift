import SwiftUI

// MARK: - User Model
struct User: Codable {
    let id: String
    let username: String
    let email: String
    let profilePicture: String?
    let preferences: Preferences?
    let demographics: Demographics?
    let isActive: Bool?
    let lastLogin: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case email
        case profilePicture
        case preferences
        case demographics
        case isActive
        case lastLogin
        case createdAt
        case updatedAt
    }
    
    struct Preferences: Codable {
        let pushNotificationsEnabled: Bool?
        let preferredNotificationTimeWindow: NotificationTimeWindow?
        let shareLocationForHeatmap: Bool?
        let privacySettings: PrivacySettings?
        
        struct NotificationTimeWindow: Codable {
            let start: Int?
            let end: Int?
        }
        
        struct PrivacySettings: Codable {
            let showMoodToStrangers: Bool?
            let anonymousMoodSharing: Bool?
        }
    }
    
    struct Demographics: Codable {
        let graduatingClass: Int?
        let major: String?
        let gender: String?
        let ethnicity: String?
        let age: Int?
    }
}
