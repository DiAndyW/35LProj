import SwiftUI

// MARK: - Home Feed View (Twitter-like combined feed)
struct HomeFeedView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var posts: [MoodPost] = []
    @State private var isLoading = false
    @State private var showingCompose = false
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with app branding
                VStack(spacing: 8) {
                    HStack {
                        Text("Morii")
                            .font(.custom("Georgia", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Quick check-in shortcut button
                        Button(action: {
                            router.navigateToMoodFlow()
                        }) {
                            Image(systemName: "plus.bubble")
                                .font(.system(size: 22))
                                .foregroundColor(.pink)
                        }
                    }
                    
                    Text("How's everyone feeling?")
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Feed content
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading feed...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                } else if posts.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "heart.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.pink.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("Welcome to your mood feed!")
                                .font(.custom("Georgia", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Check in with your mood to see posts from friends and the community.")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Button(action: {
                            router.navigateToMoodFlow()
                        }) {
                            Text("Make your first check-in")
                                .font(.custom("Georgia", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(Color.pink.opacity(0.8))
                                )
                        }
                        
                        Spacer()
                    }
                } else {
                    // Posts feed
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                MoodPostCard(post: post)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120) // Account for tab bar
                    }
                }
            }
        }
        .onAppear {
            loadFeed()
        }
        .refreshable {
            await refreshFeed()
        }
    }
    
    private func loadFeed() {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Load sample posts for now
            posts = MoodPost.samplePosts
            isLoading = false
        }
    }
    
    private func refreshFeed() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        posts = MoodPost.samplePosts.shuffled()
    }
}

// MARK: - Profile View (includes settings and analytics)
struct ProfileView: View {
    @EnvironmentObject private var router: MoodAppRouter
    @State private var userStats = UserStats.sample
    @State private var selectedProfileTab: ProfileTab = .overview
    
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
                            Text("Sarah Chen")
                                .font(.custom("Georgia", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("@sarahc")
                                .font(.custom("Georgia", size: 16))
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
                .padding(.top, 60)
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
                    .padding(.bottom, 120) // Account for tab bar
                }
            }
        }
    }
}

// MARK: - Profile Tab Views
struct ProfileOverviewView: View {
    let stats: UserStats
    
    var body: some View {
        VStack(spacing: 20) {
            // Recent activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.custom("Georgia", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    RecentActivityItem(emotion: "Happy", time: "2 hours ago", color: .yellow)
                    RecentActivityItem(emotion: "Excited", time: "Yesterday", color: .orange)
                    RecentActivityItem(emotion: "Calm", time: "2 days ago", color: .blue)
                }
            }
            
            // This week summary
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.custom("Georgia", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    WeekStatCard(title: "Check-ins", value: "5", subtitle: "This week")
                    WeekStatCard(title: "Avg Energy", value: "High", subtitle: "↑ from last week")
                    WeekStatCard(title: "Top Emotion", value: "Happy", subtitle: "3 times")
                    WeekStatCard(title: "Streak", value: "\(stats.currentStreak) days", subtitle: "Keep it up!")
                }
            }
        }
    }
}

struct ProfileAnalyticsView: View {
    let stats: UserStats
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Detailed analytics coming soon!")
                .font(.custom("Georgia", size: 18))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 40)
            
            // Placeholder for charts
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Mood trends chart")
                            .foregroundColor(.white.opacity(0.4))
                    }
                )
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Emotion distribution")
                            .foregroundColor(.white.opacity(0.4))
                    }
                )
        }
    }
}

struct ProfileSettingsView: View {
    @EnvironmentObject private var router: MoodAppRouter
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsRow(icon: "person.circle", title: "Edit Profile", subtitle: "Update your information")
            SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage notification preferences")
            SettingsRow(icon: "lock", title: "Privacy", subtitle: "Control who sees your posts")
            SettingsRow(icon: "paintbrush", title: "Appearance", subtitle: "Customize your experience")
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
                    
                    Spacer()
                }
            }
        }
    }
}
