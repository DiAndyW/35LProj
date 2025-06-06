//
//  ProfileSettingsView.swift
//  uclamoods
//
//  Created by David Sun on 5/30/25.
//

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var showingSignOutAlert = false
    
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
            SettingsRow(icon: "arrow.right.square", title: "Sign Out", subtitle: "Sign out of your account", action: {
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.prepare()
                feedback.impactOccurred()
                showingSignOutAlert = true
            })
        }
        .padding(.top, 8)
        .alert("Are you sure you want to sign out?", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                router.signOut()
            }
        } message: {
            Text("You will be returned to the login screen.")
        }
    }
}
