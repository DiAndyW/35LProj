import SwiftUI

struct ProfileOverviewView: View {
    // State for data
    @State private var posts: [MoodPost] = []
    @State private var summary: UserSummary? = nil
    
    @ObservedObject private var userDataProvider = UserDataProvider.shared
    
    @State private var isLoading: Bool = false
    @State private var summaryError: String? = nil
    @State private var postsError: String? = nil
    
    let refreshID: UUID
    
    var body: some View {
        mainContentView
            .onAppear {
                if summary == nil && posts.isEmpty {
                    Task {
                        await loadInitialData()
                    }
                }
            }
            .onChange(of: refreshID) {
                Task {
                    print("ProfileOverviewView: refreshID changed, calling refreshData()")
                    await refreshData(isPullToRefresh: true)
                }
            }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if isLoading && summary == nil && posts.isEmpty {
            VStack {
                Spacer()
                ProgressView("Loading overview...")
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
        } else {
            VStack(spacing: 20) {
                summarySection
                postsSection
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if let currentSummary = summary {
                let avgPleasantness = currentSummary.data.weeklySummary.averageMoodForWeek.averageAttributes.pleasantness
                let avgIntensity = currentSummary.data.weeklySummary.averageMoodForWeek.averageAttributes.intensity
                let avgControl = currentSummary.data.weeklySummary.averageMoodForWeek.averageAttributes.control
                let avgClarity = currentSummary.data.weeklySummary.averageMoodForWeek.averageAttributes.clarity
                
                let averageEmotion = Emotion(
                    name: currentSummary.data.weeklySummary.averageMoodForWeek.topEmotion ?? "Average",
                    color: ColorData.calculateMoodColor(pleasantness: avgPleasantness, intensity: avgIntensity) ?? .gray,
                    description: "Average mood for the week.",
                    pleasantness: avgPleasantness,
                    intensity: avgIntensity,
                    control: avgControl,
                    clarity: avgClarity
                )
                
                EmotionRadarChartView(emotion: averageEmotion)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    WeekStatCard(title: "Top Emotion", value: currentSummary.data.weeklySummary.weeklyTopMood?.name ?? "N/A")
                    WeekStatCard(title: "Check-ins", value: "\(currentSummary.data.weeklySummary.weeklyCheckinsCount)")
                }
            } else if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else {
                Text("Could not load summary. Pull to refresh.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
    }
    
    @ViewBuilder
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if !posts.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        ActivityCard(post: post.toFeedItem())
                    }
                }
            } else if let errorMsg = postsError {
                Text("Could not load posts: \(errorMsg)")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else if isLoading && posts.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if !isLoading {
                Text("No activity yet! Make a check-in to see it here.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
    }
    
    // MARK: - Data Loading Functions
    
    private func loadInitialData() async {
        guard !isLoading else { return }
        await MainActor.run {
            isLoading = true
            summaryError = nil
            postsError = nil
        }
        print("ProfileOverviewView: Loading initial data...")
        
        await refreshData(isPullToRefresh: false)
        
        print("ProfileOverviewView: Initial data load complete.")
    }
    
    private func refreshData(isPullToRefresh: Bool) async {
        print("ProfileOverviewView: Refreshing data (isPullToRefresh: \(isPullToRefresh))...")
        if !isPullToRefresh {
            await MainActor.run { isLoading = true }
        }
        await MainActor.run {
            summaryError = nil
            postsError = nil
        }
        
        async let summaryResult: () = loadSummaryAsync()
        async let feedResult: () = loadFeedAsync()
        
        _ = await summaryResult
        _ = await feedResult
        
        if !isPullToRefresh {
            await MainActor.run { isLoading = false }
        }
        print("ProfileOverviewView: Data refresh complete.")
    }
    
    @MainActor
    private func loadSummaryAsync() async {
        ProfileService.fetchSummary() { result in
            switch result {
                case .success(let fetchedSummary):
                    self.summary = fetchedSummary
                    self.summaryError = nil
                    print("ProfileOverviewView: Successfully fetched summary.")
                case .failure(let error):
                    self.summaryError = error.localizedDescription
                    self.summary = nil
                    print("ProfileOverviewView: Error fetching summary: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func loadFeedAsync() async {
        guard let userId = userDataProvider.currentUser?.id, !userId.isEmpty else {
            let errorMsg = "Invalid or missing user ID."
            print("ProfileOverviewView: Error fetching posts: \(errorMsg)")
            self.postsError = errorMsg
            self.posts = []
            return
        }
        
        MoodPostService.fetchMoodPosts(endpoint: "/api/checkin/\(userId)") { result in
            switch result {
                case .success(let fetchedPosts):
                    self.posts = fetchedPosts
                    self.postsError = nil
                    print("ProfileOverviewView: Successfully fetched \(fetchedPosts.count) posts.")
                case .failure(let error):
                    self.postsError = error.localizedDescription
                    self.posts = []
                    print("ProfileOverviewView: Error fetching posts: \(error.localizedDescription)")
            }
        }
    }
}
