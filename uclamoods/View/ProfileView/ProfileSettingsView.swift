//
//  ProfileSettingsView.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: EditProfileView()) {
                SettingsRow(icon: "person.circle", title: "Edit Profile", subtitle: "Update your information")
            }
            NavigationLink(destination: NotificationSettingsView()) {
                SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage notification preferences")
            }
            NavigationLink(destination: BlockedAccountsView()) {
                SettingsRow(icon: "person.slash", title: "Blocked Accounts", subtitle: "Manage blocked users")
            }
            //SettingsRow(icon: "questionmark.circle", title: "Help & Support", subtitle: "Get help or send feedback")
            SettingsRow(icon: "arrow.right.square", title: "Sign Out", subtitle: "Sign out of your account", action: {
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.prepare()
                feedback.impactOccurred()
                router.signOut()})
        }
        .padding(.top, 8)
    }
}
