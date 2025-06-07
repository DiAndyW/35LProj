import SwiftUI

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
    
    @State private var selectedPostForDetail: FeedItem?
    @State private var showDetailViewAnimated: Bool = false
    
    @State private var lastRefreshedDate = Date()
    
    enum ProfileTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case analytics = "Analytics"
        case settings = "Settings"
        var id: String { self.rawValue }
        func index() -> Int { ProfileTab.allCases.firstIndex(of: self) ?? 0 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        if userDataProvider.currentUser == nil && !AuthenticationService.shared.isAuthenticated {
                            ProgressView("Not authenticated or loading user...")
                                .foregroundColor(.white)
                        } else if userDataProvider.currentUser == nil && AuthenticationService.shared.isAuthenticated {
                            ProgressView("Loading Profile...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .onAppear {
                                    Task {
                                        await userDataProvider.refreshUserData()
                                    }
                                }
                        } else {
                            profileContentView(scrollProxy: scrollProxy)
                        }
                    }
                    .blur(radius: showDetailViewAnimated ? 15 : 0)
                    .disabled(showDetailViewAnimated)
                    
                    if showDetailViewAnimated {
                        detailViewOverlay(geometry: geometry)
                    }
                }
                .onReceive(router.profileTabTappedAgain) { _ in
                    print("[ProfileView]: Profile tab re-tapped. Resetting to overview.")
                    if selectedProfileTab == .overview {
                        overviewRefreshID = UUID()
                        lastRefreshedDate = Date()
                        withAnimation {
                            scrollProxy.scrollTo("profile_top", anchor: .top)
                        }
                    } else {
                        selectedProfileTab = .overview
                    }
                }
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
    private func profileContentView(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            
            VStack(spacing: 0){
                ProfileHeaderView()
                    .padding(.bottom, 8)
                
                ProfileTabViewSelector(selectedProfileTab: $selectedProfileTab, scrollProxy: scrollProxy)
                    .scaleEffect(0.9)
                    .padding(.bottom, 8)
            }
            .cornerRadius(20)
            
            ScrollView {
                Color.clear.frame(height: 0).id("profile_top")
                tabContentView
                    .id(selectedProfileTab)
                    .transition(currentContentTransition)
            }
            .refreshable {
                await userDataProvider.refreshUserData()
                
                if selectedProfileTab == .overview {
                    overviewRefreshID = UUID()
                }
                lastRefreshedDate = Date()
                withAnimation {
                    scrollProxy.scrollTo("profile_top", anchor: .top)
                }
            }
        }
    }
    
    @ViewBuilder
    private var tabContentView: some View {
        Group {
            switch selectedProfileTab {
                case .overview:
                    ProfileOverviewView(
                        refreshID: overviewRefreshID,
                        lastRefreshed: lastRefreshedDate,
                        onSelectPost: { feedItem in
                            presentDetailView(for: feedItem)
                        }
                    )
                case .analytics:
                    ProfileAnalyticsView()
                case .settings:
                    ProfileSettingsView()
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func detailViewOverlay(geometry: GeometryProxy) -> some View {
        Color.black.opacity(0.4)
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity)
            .onTapGesture { dismissDetailView() }
        
        if let postToShow = selectedPostForDetail {
            MoodPostDetailView(
                post: postToShow,
                onDismiss: dismissDetailView
            )
            .environmentObject(userDataProvider)
            .environmentObject(router)
            .frame(
                width: geometry.size.width * 0.95,
                height: max(
                    geometry.size.height * 0.5,
                    min(geometry.size.height * 0.90, 700)
                )
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
        }
    }
    
    private func presentDetailView(for feedItem: FeedItem) {
        selectedPostForDetail = feedItem
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            router.tabWithActiveDetailView = .profile
            showDetailViewAnimated = true
        }
    }
    
    private func dismissDetailView() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showDetailViewAnimated = false
            router.tabWithActiveDetailView = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectedPostForDetail = nil
        }
        lastRefreshedDate = Date()
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
        .padding(.top, 16)
    }
}

struct ProfileTabViewSelector: View {
    @Binding var selectedProfileTab: ProfileView.ProfileTab
    let scrollProxy: ScrollViewProxy
    let tabs: [ProfileView.ProfileTab] = ProfileView.ProfileTab.allCases
    
    @Namespace private var selectedTabNamespace
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    if selectedProfileTab == tab {
                        withAnimation {
                            scrollProxy.scrollTo("profile_top", anchor: .top)
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            selectedProfileTab = tab
                        }
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
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
        }
    }
}
