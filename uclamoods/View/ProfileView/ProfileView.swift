//
//  ProfileView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/28/25.
//
import SwiftUI

// MARK: - Profile View (includes settings and analytics)

struct ProfileView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var userStats = UserStats.sample
    @State private var selectedProfileTab: ProfileTab = .overview
    
    @StateObject private var userDataProvider = UserDataProvider.shared
    
    enum ProfileTab: String, CaseIterable {
        case overview = "Overview"
        case analytics = "Analytics"
        case settings = "Settings"
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Profile Header
                VStack(spacing: 20) {
                    // Profile info
                    VStack(spacing: 12) {
                        // Avatar
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                        
                        // Name and username
                        VStack(spacing: 4) {
                            Text(userDataProvider.currentUser?.username ?? "Username")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(userDataProvider.currentUser?.email ?? "Email")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Quick stats
                        HStack(spacing: 30) {
                            StatItem(value: "\(userStats.totalCheckIns)", label: "Check-ins")
                            StatItem(value: "\(userStats.currentStreak)", label: "Day Streak")
                            StatItem(value: userStats.topEmotion, label: "Top Mood")
                        }
                    }
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(ProfileTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedProfileTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.custom("Georgia", size: 16))
                                    .fontWeight(selectedProfileTab == tab ? .bold : .medium)
                                    .foregroundColor(selectedProfileTab == tab ? .pink : .white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Rectangle()
                                            .fill(selectedProfileTab == tab ? Color.pink.opacity(0.1) : Color.clear)
                                    )
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Tab content
                ScrollView {
                    Group {
                        switch selectedProfileTab {
                        case .overview:
                            ProfileOverviewView(stats: userStats)
                        case .analytics:
                            ProfileAnalyticsView(stats: userStats)
                        case .settings:
                            ProfileSettingsView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(100, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) + 70)
                }
            }
        }
    }
}
