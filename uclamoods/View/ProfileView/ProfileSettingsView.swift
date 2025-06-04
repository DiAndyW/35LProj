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
            SettingsRow(icon: "person.circle", title: "Edit Profile", subtitle: "Update your information")
            NavigationLink(destination: NotificationSettingsView()) {
                SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage notification preferences")
            }
            SettingsRow(icon: "questionmark.circle", title: "Help & Support", subtitle: "Get help or send feedback")
            
            // Logout button
            Button(action: {
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.prepare()
                feedback.impactOccurred()
                
                router.signOut()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log Out")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text("Sign out of your account")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    ProfileSettingsView()
}
