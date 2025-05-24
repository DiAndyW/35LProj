//
//  MoodNavBar.swift
//  uclamoods
//
//  Created by Di Xuan Wang on 5/16/25.
//

import SwiftUI

struct MoodNavBar: View {
    @State private var selectedTab: MainTab = .home
    @EnvironmentObject private var router: MoodAppRouter
    
    enum MainTab: String, CaseIterable {
        case home = "Home"
        case stats = "Stats"
        case friends = "Friends"
        case settings = "Settings"
        
        var iconName: String {
            switch self {
            case .home: return "house"
            case .stats: return "chart.bar"
            case .friends: return "person.2"
            case .settings: return "gear"
            }
        }
        
        // Convert MainTab to MoodAppScreen
        var toScreen: MoodAppScreen {
            switch self {
            case .home: return .home
            case .stats: return .stats
            case .friends: return .friends
            case .settings: return .settings
            }
        }
    }
    
    var body: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Spacer()
                
                Button(action: {
                    selectedTab = tab
                    
                    switch tab {
                    case .home:
                        router.navigateToHome()
                    case .stats:
                        router.navigateToStats()
                    case .friends:
                        router.navigateToFriends()
                    case .settings:
                        router.navigateToSettings()
                    }
                }) {
                    VStack {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isTabSelected(tab) ? .blue : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .foregroundStyle(isTabSelected(tab) ? .blue : .gray)
                    }
                }
                Spacer()
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 15)
        .background(Color(UIColor.systemBackground))
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 20, bottomLeading: 0,
            bottomTrailing: 0, topTrailing: 20
        )))
        .shadow(radius: 5)
        .onAppear {
            selectedTab = getCurrentTab()
        }
    }
    
    private func isTabSelected(_ tab: MainTab) -> Bool {
        switch router.currentScreen {
        case .home:
            return tab == .home
        case .stats:
            return tab == .stats
        case .friends:
            return tab == .friends
        case .settings:
            return tab == .settings
        default:
            return tab == .home
        }
    }
       
    // Get the current tab based on the router's current screen
    private func getCurrentTab() -> MainTab {
        switch router.currentScreen {
        case .home:
            return .home
        case .stats:
            return .stats
        case .friends:
            return .friends
        case .settings:
            return .settings
        default:
            return .home
        }
    }
}
