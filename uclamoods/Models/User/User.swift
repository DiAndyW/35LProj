//
//  User.swift
//  uclamoods
//
//  Created by Yang Gao on 6/1/25.
//
import SwiftUI

// MARK: - User Model
struct User: Codable {
    let id: String
    let username: String
    let email: String
    let profilePicture: String?
    let demographics: Demographics?
    let preferences: Preferences?
    let isActive: Bool
    let lastLogin: Date?
    
    struct Demographics: Codable {
        let graduatingClass: Int?
        let major: String?
        let gender: String?
        let ethnicity: String?
        let age: Int?
    }
    
    struct Preferences: Codable {
        let pushNotificationsEnabled: Bool
        let shareLocationForHeatmap: Bool
        let privacySettings: PrivacySettings?
        
        struct PrivacySettings: Codable {
            let showMoodToStrangers: Bool
            let anonymousMoodSharing: Bool
        }
    }
}
