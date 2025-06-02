import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
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

enum TabTransitionDirection: Equatable {
    case forward
    case backward
    case none
}

struct ProfileView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @EnvironmentObject private var userDataProvider: UserDataProvider
    
    @State private var selectedProfileTab: ProfileTab = .overview
    @State private var tabTransitionDirection: TabTransitionDirection = .none
    @State private var overviewRefreshID = UUID()
    
    @State private var isLoadingProfileData: Bool = true
    
    enum ProfileTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case analytics = "Analytics"
        case settings = "Settings"
        var id: String { self.rawValue }
        func index() -> Int { ProfileTab.allCases.firstIndex(of: self) ?? 0 }
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if isLoadingProfileData {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .onAppear {
                        if isLoadingProfileData {
                            Task {
                                print("ProfileView: Initial data fetch started.")
                                await userDataProvider.refreshUserData()
                                await MainActor.run {
                                    isLoadingProfileData = false
                                    print("ProfileView: Initial data fetch complete. Showing content.")
                                }
                            }
                        }
                    }
            } else {
                profileContentView
            }
        }
        .onChange(of: selectedProfileTab) { oldValue, newValue in
            if oldValue.index() < newValue.index() {
                self.tabTransitionDirection = .forward
            } else if oldValue.index() > newValue.index() {
                self.tabTransitionDirection = .backward
            } else {
                self.tabTransitionDirection = .none
            }
        }
    }
    
    @ViewBuilder
    private var profileContentView: some View {
        VStack(spacing: 0) {
            ProfileHeaderView() //
                .padding(.bottom, 20)
            
            ProfileTabViewSelector(selectedProfileTab: $selectedProfileTab) //
                .padding(.bottom, 20)
            
            ScrollView {
                tabContentView
                    .id(selectedProfileTab)
                    .transition(currentContentTransition)
            }
            .refreshable {
                if selectedProfileTab == .overview {
                    print("ProfileView: Refresh triggered for Overview tab.")
                    overviewRefreshID = UUID()
                }
                print("ProfileView: Refreshable initiated userDataProvider.refreshUserData()")
                await userDataProvider.refreshUserData() //
            }
        }
    }
    
    @ViewBuilder
    private var tabContentView: some View {
        Group {
            switch selectedProfileTab {
                case .overview:
                    ProfileOverviewView(refreshID: overviewRefreshID)
                case .analytics:
                    ProfileAnalyticsView() //
                case .settings:
                    ProfileSettingsView() //
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) + 80)
    }
    
    private var currentContentTransition: AnyTransition {
        let animationDuration = 0.35
        switch tabTransitionDirection {
            case .forward:
                return .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                )
                .combined(with: .opacity)
                .animation(.easeInOut(duration: animationDuration))
            case .backward:
                return .asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                )
                .combined(with: .opacity)
                .animation(.easeInOut(duration: animationDuration))
            case .none:
                return .opacity
                    .animation(.easeInOut(duration: animationDuration))
        }
    }
}
