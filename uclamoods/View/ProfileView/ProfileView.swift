import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject var userDataProvider: UserDataProvider
    
    var body: some View {
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
                
                Text(userDataProvider.currentUser?.email ?? "Email")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 20)
    }
}

struct ProfileTabViewSelector: View {
    @Binding var selectedProfileTab: ProfileView.ProfileTab
    let tabs: [ProfileView.ProfileTab] = ProfileView.ProfileTab.allCases
    
    @Namespace private var selectedTabNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
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
                            ZStack {
                                if selectedProfileTab == tab {
                                    Capsule()
                                        .fill(Color.pink.opacity(0.2))
                                        .matchedGeometryEffect(id: "selectedTabBackground", in: selectedTabNamespace)
                                }
                                Capsule()
                                    .stroke(selectedProfileTab == tab ? Color.pink : Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        )
                }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .padding(.horizontal, 20)
    }
}


struct ProfileView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @ObservedObject private var userDataProvider = UserDataProvider.shared
    
    @State private var selectedProfileTab: ProfileTab = .overview
    @State private var overviewRefreshID = UUID()
    
    enum ProfileTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case analytics = "Analytics"
        case settings = "Settings"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ProfileHeaderView(userDataProvider: userDataProvider)
                    .padding(.bottom, 20)
                
                ProfileTabViewSelector(selectedProfileTab: $selectedProfileTab)
                    .padding(.bottom, 20)
                
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
                    .id(selectedProfileTab)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 30)),
                        removal: .opacity.combined(with: .offset(x: -30))
                    ).animation(.easeInOut(duration: 0.3)))
                    .padding(.horizontal, 20)
                    .padding(.bottom, (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) + 80)
                }
                .refreshable {
                    if selectedProfileTab == .overview {
                        print("ProfileView: Refresh triggered for Overview tab.")
                        overviewRefreshID = UUID()
                    }
                    await userDataProvider.refreshUserData()
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
