//
//  ProfileView.swift
//  uclamoods
//
//  Created by Yang Gao on 5/28/25.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var selectedProfileTab: ProfileTab = .overview
    @StateObject private var userDataProvider = UserDataProvider.shared
    
    @State private var overviewRefreshID = UUID()
    
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
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                        
                        VStack(spacing: 4) {
                            Text(userDataProvider.currentUser?.username ?? "Username")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("@\(userDataProvider.currentUser?.email ?? "Email")")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        HStack(spacing: 30) { /* For stats if any */ }
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
                                ProfileOverviewView(refreshID: overviewRefreshID)
                            case .analytics:
                                ProfileAnalyticsView()
                            case .settings:
                                ProfileSettingsView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(100, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) + 70)
                    .refreshable {
                        if selectedProfileTab == .overview {
                            print("ProfileView: Refresh triggered for Overview tab.")
                            overviewRefreshID = UUID()
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await userDataProvider.refreshUserData()
                }
            }
        }
    }
}
