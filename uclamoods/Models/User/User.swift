// User.swift
import SwiftUI

// MARK: - User Model
struct User: Codable {
    let id: String
    let username: String
    let email: String
    let profilePicture: String?
    var preferences: Preferences? // Made var to allow modification
    let demographics: Demographics?
    let isActive: Bool?
    let lastLogin: Date?
    let createdAt: Date?
    let updatedAt: Date?
    var fcmToken: String?

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
        case fcmToken = ""
    }

    struct Preferences: Codable {
        var pushNotificationsEnabled: Bool?
        var notificationHourPST: Int?
        var notificationMinutePST: Int?

        var shareLocationForHeatmap: Bool?
        var privacySettings: PrivacySettings?
        
        struct NotificationTimeWindow: Codable { // This struct is no longer directly used for the main notification time
            let start: Int?
            let end: Int?
        }

        struct PrivacySettings: Codable {
            var showMoodToStrangers: Bool?
            var anonymousMoodSharing: Bool?
        }

        init(pushNotificationsEnabled: Bool? = true,
             notificationHourPST: Int? = 13, // Default 1 PM PST
             notificationMinutePST: Int? = 0, // Default 00 minutes
             shareLocationForHeatmap: Bool? = false,
             privacySettings: PrivacySettings? = Preferences.PrivacySettings(showMoodToStrangers: false, anonymousMoodSharing: true)) {
            self.pushNotificationsEnabled = pushNotificationsEnabled
            self.notificationHourPST = notificationHourPST
            self.notificationMinutePST = notificationMinutePST
            self.shareLocationForHeatmap = shareLocationForHeatmap
            self.privacySettings = privacySettings
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
